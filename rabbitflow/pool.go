package main

import (
	"context"
	"slices"
	"sync"
	"time"
)

type Worker struct {
	ID        int       `json:"id"`
	Busy      bool      `json:"busy"`
	Retiring  bool      `json:"retiring"`
	EventID   string    `json:"eventId"`
	Kind      string    `json:"kind"`
	StartedAt time.Time `json:"startedAt"`
	WorkMS    int       `json:"workMs"`
	Completed int       `json:"completed"`
	stop      chan struct{}
}

// Pool counts retiring workers until their goroutines have actually exited.
// A resize never starts a goroutine for each delivery.
type Pool struct {
	mu      sync.Mutex
	workers map[int]*Worker
	next    int
	ctx     context.Context
	cancel  context.CancelFunc
	wg      sync.WaitGroup
	run     func(context.Context, int, <-chan struct{})
}

func NewPool(ctx context.Context, run func(context.Context, int, <-chan struct{})) *Pool {
	ctx, cancel := context.WithCancel(ctx)
	return &Pool{workers: make(map[int]*Worker), ctx: ctx, cancel: cancel, run: run}
}

func (p *Pool) Resize(target int) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.ctx.Err() != nil {
		return
	}
	active := 0
	for _, w := range p.workers {
		if !w.Retiring {
			active++
		}
	}
	// Retire idle workers first; busy workers finish their current delivery.
	for _, busy := range []bool{false, true} {
		for _, w := range p.workers {
			if active <= target {
				break
			}
			if !w.Retiring && w.Busy == busy {
				w.Retiring = true
				close(w.stop)
				active--
			}
		}
	}
	for len(p.workers) < target {
		p.next++
		id := p.next
		w := &Worker{ID: id, stop: make(chan struct{})}
		p.workers[id] = w
		p.wg.Go(func() {
			defer func() { p.mu.Lock(); delete(p.workers, id); p.mu.Unlock() }()
			p.run(p.ctx, id, w.stop)
		})
	}
}

func (p *Pool) Update(id int, update func(*Worker)) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if w := p.workers[id]; w != nil {
		update(w)
	}
}

func (p *Pool) Snapshot() []Worker {
	p.mu.Lock()
	defer p.mu.Unlock()
	out := make([]Worker, 0, len(p.workers))
	for _, w := range p.workers {
		out = append(out, *w)
	}
	slices.SortFunc(out, func(a, b Worker) int { return a.ID - b.ID })
	return out
}
func (p *Pool) Count() int { return len(p.Snapshot()) }
func (p *Pool) Active() int {
	n := 0
	for _, w := range p.Snapshot() {
		if !w.Retiring {
			n++
		}
	}
	return n
}
func (p *Pool) Stop() {
	// Synchronize with Resize so no Add can race Wait on an empty pool.
	p.mu.Lock()
	p.cancel()
	p.mu.Unlock()
	p.wg.Wait()
}

type PoolConfig struct {
	Min              int `json:"min"`
	Max              int `json:"max"`
	BacklogPerWorker int `json:"backlogPerWorker"`
	CooldownSeconds  int `json:"cooldownSeconds"`
}

type Scaler struct{ lowSince time.Time }

func (s *Scaler) Target(now time.Time, ready, busy, current int, c PoolConfig) int {
	desired := min(c.Max, max(c.Min, (ready+busy+c.BacklogPerWorker-1)/c.BacklogPerWorker))
	if desired >= current {
		s.lowSince = time.Time{}
		return desired
	}
	if s.lowSince.IsZero() {
		s.lowSince = now
	}
	if now.Sub(s.lowSince) < time.Duration(c.CooldownSeconds)*time.Second {
		return min(current, c.Max)
	}
	return desired
}
