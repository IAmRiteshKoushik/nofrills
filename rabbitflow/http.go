package main

import (
	"embed"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"net/http"
	"time"
)

//go:embed web/*
var assets embed.FS

func readJSON(w http.ResponseWriter, r *http.Request, v any) bool {
	r.Body = http.MaxBytesReader(w, r.Body, 4096)
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(v); err != nil {
		http.Error(w, "Invalid JSON request.", http.StatusBadRequest)
		return false
	}
	if err := d.Decode(new(any)); err != io.EOF {
		http.Error(w, "Expected one JSON object.", http.StatusBadRequest)
		return false
	}
	return true
}
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func (a *App) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/state", func(w http.ResponseWriter, r *http.Request) { writeJSON(w, 200, a.snapshot()) })
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		status := http.StatusOK
		if !a.snapshot().Connected {
			status = http.StatusServiceUnavailable
		}
		writeJSON(w, status, map[string]bool{"connected": status == 200})
	})
	mux.HandleFunc("POST /api/burst", func(w http.ResponseWriter, r *http.Request) {
		var body struct {
			Count int `json:"count"`
		}
		if !readJSON(w, r, &body) {
			return
		}
		if body.Count < 1 || body.Count > 1000 {
			http.Error(w, "Burst must contain 1 to 1000 events.", 400)
			return
		}
		a.mu.Lock()
		defer a.mu.Unlock()
		if !a.state.Connected {
			http.Error(w, "RabbitMQ is disconnected.", 503)
			return
		}
		if a.state.Pending > 0 {
			http.Error(w, "A burst is still being published. Try again when it finishes.", 409)
			return
		}
		select {
		case a.burst <- body.Count:
			a.state.Pending += body.Count
			a.logLocked("publish", fmt.Sprintf("Burst queued: %d events", body.Count))
			writeJSON(w, http.StatusAccepted, map[string]int{"queued": body.Count})
		default:
			http.Error(w, "Producer is busy.", 409)
		}
	})
	mux.HandleFunc("POST /api/producer", func(w http.ResponseWriter, r *http.Request) {
		var cfg ProducerConfig
		if !readJSON(w, r, &cfg) {
			return
		}
		if cfg.Rate < 1 || cfg.Rate > 200 || cfg.WorkMS < 50 || cfg.WorkMS > 5000 {
			http.Error(w, "Rate must be 1–200 events/s; work duration must be 50–5000 ms.", 400)
			return
		}
		a.mu.Lock()
		a.state.Producer = cfg
		label := "paused"
		if cfg.Enabled {
			label = "running"
		}
		a.logLocked("producer", fmt.Sprintf("Producer %s · %d events/s · %d ms/event", label, cfg.Rate, cfg.WorkMS))
		a.mu.Unlock()
		writeJSON(w, 200, cfg)
	})
	mux.HandleFunc("POST /api/pool", func(w http.ResponseWriter, r *http.Request) {
		var cfg PoolConfig
		if !readJSON(w, r, &cfg) {
			return
		}
		if cfg.Min < 1 || cfg.Max < cfg.Min || cfg.Max > 64 || cfg.BacklogPerWorker < 1 || cfg.BacklogPerWorker > 100 || cfg.CooldownSeconds < 2 || cfg.CooldownSeconds > 60 {
			http.Error(w, "Use 1 ≤ min ≤ max ≤ 64, backlog 1–100, and cooldown 2–60 seconds.", 400)
			return
		}
		a.mu.Lock()
		defer a.mu.Unlock()
		if a.pool != nil && cfg.Max < a.pool.Count() {
			http.Error(w, "Maximum is below the live worker count. Pause the producer and let the pool shrink first.", 409)
			return
		}
		a.state.Config = cfg
		a.logLocked("config", fmt.Sprintf("Pool bounds %d–%d · %d events/worker · %ds cooldown", cfg.Min, cfg.Max, cfg.BacklogPerWorker, cfg.CooldownSeconds))
		writeJSON(w, 200, cfg)
	})
	mux.HandleFunc("GET /api/events", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/event-stream")
		w.Header().Set("Cache-Control", "no-cache")
		w.Header().Set("X-Accel-Buffering", "no")
		controller := http.NewResponseController(w)
		ticker := time.NewTicker(250 * time.Millisecond)
		defer ticker.Stop()
		for {
			// A slow or abandoned dashboard must never block the broker or workers.
			_ = controller.SetWriteDeadline(time.Now().Add(5 * time.Second))
			body, _ := json.Marshal(a.snapshot())
			if _, err := fmt.Fprintf(w, "data: %s\n\n", body); err != nil {
				return
			}
			if err := controller.Flush(); err != nil {
				return
			}
			select {
			case <-r.Context().Done():
				return
			case <-ticker.C:
			}
		}
	})
	web, _ := fs.Sub(assets, "web")
	mux.Handle("GET /", http.FileServerFS(web))
	// The local dashboard has no authentication. Block cross-origin browser writes.
	protected := http.NewCrossOriginProtection().Handler(mux)
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; connect-src 'self'; img-src 'self' data:; object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
		protected.ServeHTTP(w, r)
	})
}
