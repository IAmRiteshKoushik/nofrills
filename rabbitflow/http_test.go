package main

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func request(t *testing.T, handler http.Handler, method, path, body string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, path, bytes.NewBufferString(body))
	if body != "" {
		req.Header.Set("Content-Type", "application/json")
	}
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, req)
	return response
}

func TestPoolConfigurationRejectsMaximumBelowLiveCount(t *testing.T) {
	app := NewApp("amqp://unused", "test")
	app.pool = NewPool(t.Context(), func(ctx context.Context, _ int, _ <-chan struct{}) {
		<-ctx.Done()
	})
	defer app.pool.Stop()
	app.pool.Resize(4)

	response := request(t, app.Handler(), http.MethodPost, "/api/pool",
		`{"min":1,"max":2,"backlogPerWorker":8,"cooldownSeconds":8}`)
	if response.Code != http.StatusConflict {
		t.Fatalf("status = %d, want %d: %s", response.Code, http.StatusConflict, response.Body.String())
	}
}

func TestHTTPValidationAndState(t *testing.T) {
	app := NewApp("amqp://unused", "test")
	handler := app.Handler()

	invalid := request(t, handler, http.MethodPost, "/api/burst", `{"count":1001}`)
	if invalid.Code != http.StatusBadRequest {
		t.Fatalf("invalid burst status = %d", invalid.Code)
	}

	state := request(t, handler, http.MethodGet, "/api/state", "")
	if state.Code != http.StatusOK {
		t.Fatalf("state status = %d", state.Code)
	}
	var decoded State
	if err := json.Unmarshal(state.Body.Bytes(), &decoded); err != nil {
		t.Fatal(err)
	}
	if decoded.Queue != "test" || decoded.Connected {
		t.Fatalf("unexpected state: queue=%q connected=%v", decoded.Queue, decoded.Connected)
	}
}
