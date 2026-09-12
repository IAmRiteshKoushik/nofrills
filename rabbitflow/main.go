package main

import (
	"cmp"
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	a := NewApp(cmp.Or(os.Getenv("AMQP_URL"), "amqp://demo:demo@localhost:5672/"), cmp.Or(os.Getenv("QUEUE_NAME"), "rabbitflow.events"))
	addr := cmp.Or(os.Getenv("HTTP_ADDR"), "127.0.0.1:8080")
	server := &http.Server{Addr: addr, Handler: a.Handler(), ReadHeaderTimeout: 5 * time.Second, IdleTimeout: 60 * time.Second}
	var wg sync.WaitGroup
	wg.Go(func() { a.Run(ctx) })
	wg.Go(func() {
		slog.Info("Rabbitflow listening", "address", addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("HTTP server failed", "error", err)
			stop()
		}
	})
	<-ctx.Done()
	// Close streaming HTTP connections. Unacknowledged work is requeued when the
	// AMQP session closes; no event is acknowledged just because shutdown began.
	_ = server.Close()
	wg.Wait()
}
