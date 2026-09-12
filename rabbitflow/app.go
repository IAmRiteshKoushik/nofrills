package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"sync"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
)

type Event struct {
	ID        string    `json:"id"`
	Kind      string    `json:"kind"`
	WorkMS    int       `json:"workMs"`
	CreatedAt time.Time `json:"createdAt"`
}
type ProducerConfig struct {
	Enabled bool `json:"enabled"`
	Rate    int  `json:"rate"`
	WorkMS  int  `json:"workMs"`
}
type LogEntry struct {
	Time    time.Time `json:"time"`
	Kind    string    `json:"kind"`
	Message string    `json:"message"`
}
type Sample struct {
	Time         time.Time `json:"time"`
	Ready        int       `json:"ready"`
	Workers      int       `json:"workers"`
	Busy         int       `json:"busy"`
	PublishRate  float64   `json:"publishRate"`
	CompleteRate float64   `json:"completeRate"`
}
type State struct {
	Connected   bool           `json:"connected"`
	Error       string         `json:"error"`
	Queue       string         `json:"queue"`
	Ready       int            `json:"ready"`
	SampledAt   time.Time      `json:"sampledAt"`
	Published   int            `json:"published"`
	Completed   int            `json:"completed"`
	Rejected    int            `json:"rejected"`
	Redelivered int            `json:"redelivered"`
	Pending     int            `json:"pending"`
	Producer    ProducerConfig `json:"producer"`
	Config      PoolConfig     `json:"config"`
	Workers     []Worker       `json:"workers"`
	History     []Sample       `json:"history"`
	Logs        []LogEntry     `json:"logs"`
	Now         time.Time      `json:"now"`
}
type App struct {
	mu       sync.Mutex
	state    State
	pool     *Pool
	session  *Session
	url      string
	burst    chan int
	sequence int
	runID    string
}
type Session struct {
	conn      *amqp.Connection
	pubConn   *amqp.Connection
	monitor   *amqp.Channel
	publisher *amqp.Channel
	failure   chan error
}

func NewApp(url, queue string) *App {
	return &App{url: url, burst: make(chan int, 1), runID: fmt.Sprintf("%x", time.Now().UnixNano()), state: State{
		Queue: queue, Producer: ProducerConfig{Rate: 10, WorkMS: 800},
		Config:  PoolConfig{Min: 2, Max: 16, BacklogPerWorker: 8, CooldownSeconds: 8},
		History: []Sample{}, Logs: []LogEntry{}, Workers: []Worker{},
	}}
}
func (a *App) logLocked(kind, message string) {
	a.state.Logs = append([]LogEntry{{time.Now(), kind, message}}, a.state.Logs...)
	if len(a.state.Logs) > 80 {
		a.state.Logs = a.state.Logs[:80]
	}
}
func (a *App) snapshot() State {
	a.mu.Lock()
	defer a.mu.Unlock()
	s := a.state
	s.Now = time.Now()
	if a.pool != nil {
		s.Workers = a.pool.Snapshot()
	} else {
		s.Workers = []Worker{}
	}
	// These slices are changed on subsequent samples; copy before encoding.
	s.History = append([]Sample{}, s.History...)
	s.Logs = append([]LogEntry{}, s.Logs...)
	return s
}

func openSession(url, queue string) (s *Session, err error) {
	s = &Session{failure: make(chan error, 1)}
	defer func() {
		if err != nil {
			s.close()
		}
	}()
	cfg := amqp.Config{Heartbeat: 5 * time.Second, Dial: amqp.DefaultDial(5 * time.Second)}
	s.conn, err = amqp.DialConfig(url, cfg)
	if err != nil {
		return
	}
	s.monitor, err = s.conn.Channel()
	if err != nil {
		return
	}
	_, err = s.monitor.QueueDeclare(queue, true, false, false, false, nil)
	if err != nil {
		return
	}
	s.pubConn, err = amqp.DialConfig(url, cfg)
	if err != nil {
		return
	}
	s.publisher, err = s.pubConn.Channel()
	if err != nil {
		return
	}
	err = s.publisher.Confirm(false)
	return
}
func (s *Session) close() {
	if s.pubConn != nil {
		_ = s.pubConn.Close()
	}
	if s.conn != nil {
		_ = s.conn.Close()
	}
}
func (s *Session) fail(err error) {
	select {
	case s.failure <- err:
	default:
	}
}

func (a *App) Run(ctx context.Context) {
	var producer sync.WaitGroup
	producer.Go(func() { a.produce(ctx) })
	defer producer.Wait()
	for ctx.Err() == nil {
		s, err := openSession(a.url, a.state.Queue)
		if err == nil {
			err = a.consumeSession(ctx, s)
			s.close()
		}
		a.mu.Lock()
		a.session = nil
		a.pool = nil
		a.state.Connected = false
		if ctx.Err() == nil {
			// Never expose the AMQP URL, which may contain credentials.
			a.state.Error = "RabbitMQ unavailable. Retrying in 2 seconds."
			a.logLocked("error", a.state.Error)
		}
		a.mu.Unlock()
		if ctx.Err() != nil {
			return
		}
		slog.Warn("broker connection interrupted", "cause", safeBrokerError(err))
		select {
		case <-ctx.Done():
			return
		case <-time.After(2 * time.Second):
		}
	}
}
func safeBrokerError(err error) string {
	if err == nil {
		return "connection closed"
	}
	// The dashboard receives a generic error; logs avoid URL-bearing dial errors too.
	return fmt.Sprintf("%T", err)
}

func (a *App) consumeSession(ctx context.Context, s *Session) error {
	sessionCtx, cancel := context.WithCancel(ctx)
	defer cancel()
	p := NewPool(sessionCtx, func(ctx context.Context, id int, stop <-chan struct{}) { a.worker(ctx, s, id, stop) })
	defer p.Stop()
	a.mu.Lock()
	a.session = s
	a.pool = p
	a.state.Connected = true
	a.state.Error = ""
	a.logLocked("connection", "RabbitMQ connected. Workers ready.")
	cfg := a.state.Config
	p.Resize(cfg.Min)
	a.mu.Unlock()
	closed := s.conn.NotifyClose(make(chan *amqp.Error, 1))
	pubClosed := s.pubConn.NotifyClose(make(chan *amqp.Error, 1))
	ticker := time.NewTicker(500 * time.Millisecond)
	defer ticker.Stop()
	scaler := Scaler{}
	last := time.Now()
	lastPublished, lastCompleted := 0, 0
	a.mu.Lock()
	lastPublished = a.state.Published
	lastCompleted = a.state.Completed
	a.mu.Unlock()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case err := <-closed:
			return err
		case err := <-pubClosed:
			return err
		case err := <-s.failure:
			return err
		case now := <-ticker.C:
			q, err := s.monitor.QueueInspect(a.state.Queue)
			if err != nil {
				return err
			}
			a.mu.Lock()
			workers := p.Snapshot()
			busy := 0
			for _, w := range workers {
				if w.Busy {
					busy++
				}
			}
			cfg = a.state.Config
			target := scaler.Target(now, q.Messages, busy, len(workers), cfg)
			if target != p.Active() {
				a.logLocked("scale", fmt.Sprintf("%d → %d workers · %d ready, %d busy", p.Active(), target, q.Messages, busy))
			}
			p.Resize(target)
			elapsed := now.Sub(last).Seconds()
			a.state.Ready = q.Messages
			a.state.SampledAt = now
			a.state.History = append(a.state.History, Sample{now, q.Messages, p.Count(), busy, float64(a.state.Published-lastPublished) / elapsed, float64(a.state.Completed-lastCompleted) / elapsed})
			if len(a.state.History) > 120 {
				a.state.History = a.state.History[len(a.state.History)-120:]
			}
			last = now
			lastPublished = a.state.Published
			lastCompleted = a.state.Completed
			a.mu.Unlock()
		}
	}
}

func (a *App) worker(ctx context.Context, s *Session, id int, stop <-chan struct{}) {
	ch, err := s.conn.Channel()
	if err != nil {
		s.fail(err)
		return
	}
	defer ch.Close()
	if err = ch.Qos(1, 0, false); err != nil {
		s.fail(err)
		return
	}
	deliveries, err := ch.Consume(a.state.Queue, "", false, false, false, false, nil)
	if err != nil {
		s.fail(err)
		return
	}
	for {
		// Check retirement before selecting a new delivery. Closing the AMQP channel
		// returns any prefetched, unacknowledged message to the broker.
		select {
		case <-ctx.Done():
			return
		case <-stop:
			return
		default:
		}
		var d amqp.Delivery
		select {
		case <-ctx.Done():
			return
		case <-stop:
			return
		case value, ok := <-deliveries:
			if !ok {
				if ctx.Err() == nil {
					s.fail(fmt.Errorf("worker delivery channel closed"))
				}
				return
			}
			d = value
		}
		// The stop signal and a delivery can become ready together. Recheck after
		// receiving so a retiring worker cannot start one more event by chance.
		select {
		case <-stop:
			if err = d.Nack(false, true); err != nil {
				s.fail(err)
			}
			return
		default:
		}
		var event Event
		if err = json.Unmarshal(d.Body, &event); err != nil || event.ID == "" || event.WorkMS < 50 || event.WorkMS > 5000 {
			if err = d.Nack(false, false); err != nil {
				s.fail(err)
				return
			}
			a.mu.Lock()
			a.state.Rejected++
			a.logLocked("error", "Rejected malformed event.")
			a.mu.Unlock()
			continue
		}
		a.mu.Lock()
		p := a.pool
		if d.Redelivered {
			a.state.Redelivered++
		}
		a.mu.Unlock()
		p.Update(id, func(w *Worker) {
			w.Busy = true
			w.EventID = event.ID
			w.Kind = event.Kind
			w.StartedAt = time.Now()
			w.WorkMS = event.WorkMS
		})
		// Replace this timer with the real event handler. Cancellation leaves the
		// delivery unacknowledged so RabbitMQ can redeliver it.
		timer := time.NewTimer(time.Duration(event.WorkMS) * time.Millisecond)
		select {
		case <-ctx.Done():
			timer.Stop()
			return
		case <-timer.C:
		}
		if err = d.Ack(false); err != nil {
			s.fail(err)
			return
		}
		p.Update(id, func(w *Worker) { w.Busy = false; w.Completed++; w.EventID = "" })
		a.mu.Lock()
		a.state.Completed++
		a.mu.Unlock()
	}
}

// One producer goroutine owns the publisher channel and both steady and burst
// traffic. Burst requests have one bounded slot; publishing uses confirms.
func (a *App) produce(ctx context.Context) {
	ticker := time.NewTicker(20 * time.Millisecond)
	defer ticker.Stop()
	pending := 0
	credit := 0.0
	last := time.Now()
	for {
		select {
		case <-ctx.Done():
			return
		case n := <-a.burst:
			pending += n
		case now := <-ticker.C:
			a.mu.Lock()
			cfg := a.state.Producer
			s := a.session
			a.mu.Unlock()
			elapsed := now.Sub(last).Seconds()
			last = now
			if s == nil {
				credit = 0
				continue
			}
			if cfg.Enabled {
				credit = min(20, credit+elapsed*float64(cfg.Rate))
			} else {
				credit = 0
			}
			for range 20 {
				burst := pending > 0
				if !burst && credit < 1 {
					break
				}
				if burst {
					pending--
				} else {
					credit--
				}
				a.mu.Lock()
				a.sequence++
				seq := a.sequence
				a.mu.Unlock()
				event := Event{fmt.Sprintf("%s-%05d", a.runID, seq), []string{"order.created", "email.queued", "report.requested"}[seq%3], cfg.WorkMS, time.Now()}
				body, _ := json.Marshal(event)
				confirmation, err := s.publisher.PublishWithDeferredConfirm("", a.state.Queue, false, false, amqp.Publishing{ContentType: "application/json", DeliveryMode: amqp.Persistent, MessageId: event.ID, Timestamp: event.CreatedAt, Body: body})
				if err == nil {
					confirmCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
					var ack bool
					ack, err = confirmation.WaitContext(confirmCtx)
					cancel()
					if err == nil && !ack {
						err = fmt.Errorf("publish was negatively acknowledged")
					}
				}
				a.mu.Lock()
				if burst {
					a.state.Pending--
				}
				if err == nil {
					a.state.Published++
				} else {
					a.state.Error = "Publish not confirmed. Delivery is uncertain; this event was not retried."
					a.logLocked("error", a.state.Error)
				}
				a.mu.Unlock()
				if err != nil {
					s.fail(err)
					break
				}
			}
		}
	}
}
