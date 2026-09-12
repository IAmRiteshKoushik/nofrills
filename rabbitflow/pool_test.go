package main

import (
	"context"
	"sync/atomic"
	"testing"
	"time"
)

func eventually(t *testing.T, f func() bool) {
	t.Helper()
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		if f() {
			return
		}
		time.Sleep(5 * time.Millisecond)
	}
	t.Fatal("condition did not become true")
}

func TestPoolBoundsIncludeRetiringWorkers(t *testing.T) {
	var live, peak atomic.Int64
	release := make(chan struct{})
	p := NewPool(t.Context(), func(ctx context.Context, id int, retire <-chan struct{}) {
		n := live.Add(1)
		for old := peak.Load(); n > old && !peak.CompareAndSwap(old, n); old = peak.Load() {
		}
		defer live.Add(-1)
		select {
		case <-retire:
		case <-ctx.Done():
			return
		}
		select {
		case <-release:
		case <-ctx.Done():
		}
	})
	defer p.Stop()
	p.Resize(4)
	eventually(t, func() bool { return live.Load() == 4 })
	p.Resize(1)
	p.Resize(4)
	if p.Count() != 4 {
		t.Fatalf("retiring workers lost from count: %d", p.Count())
	}
	if p.Active() != 1 {
		t.Fatalf("retiring workers should not be replaced until they exit: %d", p.Active())
	}
	close(release)
	eventually(t, func() bool { return p.Count() == 1 })
	p.Resize(4)
	eventually(t, func() bool { return p.Count() == 4 })
	if peak.Load() > 4 {
		t.Fatalf("worker bound exceeded: %d", peak.Load())
	}
}

func TestScalingBacklogAndCooldown(t *testing.T) {
	s := Scaler{}
	cfg := PoolConfig{Min: 2, Max: 16, BacklogPerWorker: 8, CooldownSeconds: 8}
	now := time.Now()
	if got := s.Target(now, 120, 2, 2, cfg); got != 16 {
		t.Fatalf("burst target %d", got)
	}
	if got := s.Target(now.Add(time.Second), 0, 0, 16, cfg); got != 16 {
		t.Fatalf("shrunk before cooldown: %d", got)
	}
	if got := s.Target(now.Add(10*time.Second), 0, 0, 16, cfg); got != 2 {
		t.Fatalf("did not shrink: %d", got)
	}
	if got := s.Target(now.Add(11*time.Second), 100000, 16, 2, cfg); got != 16 {
		t.Fatalf("ceiling %d", got)
	}
}
