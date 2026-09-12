package main

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestTodoCRUD(t *testing.T) {
	t.Parallel()
	handler := (&server{store: newTodoStore()}).routes()

	create := request(t, handler, http.MethodPost, "/todos", `{"title":"Learn Orval","details":"Generate hooks."}`)
	if create.Code != http.StatusCreated {
		t.Fatalf("create status = %d, want %d; body = %s", create.Code, http.StatusCreated, create.Body.String())
	}
	var created Todo
	if err := json.NewDecoder(create.Body).Decode(&created); err != nil {
		t.Fatal(err)
	}
	if created.ID != "1" || created.Completed {
		t.Fatalf("created TODO = %#v", created)
	}

	list := request(t, handler, http.MethodGet, "/todos", "")
	if list.Code != http.StatusOK {
		t.Fatalf("list status = %d, want %d", list.Code, http.StatusOK)
	}

	update := request(t, handler, http.MethodPatch, "/todos/1", `{"completed":true}`)
	if update.Code != http.StatusOK {
		t.Fatalf("update status = %d, want %d; body = %s", update.Code, http.StatusOK, update.Body.String())
	}
	var updated Todo
	if err := json.NewDecoder(update.Body).Decode(&updated); err != nil {
		t.Fatal(err)
	}
	if !updated.Completed || updated.Title != created.Title {
		t.Fatalf("updated TODO = %#v", updated)
	}

	deleted := request(t, handler, http.MethodDelete, "/todos/1", "")
	if deleted.Code != http.StatusNoContent {
		t.Fatalf("delete status = %d, want %d", deleted.Code, http.StatusNoContent)
	}
	missing := request(t, handler, http.MethodGet, "/todos/1", "")
	if missing.Code != http.StatusNotFound {
		t.Fatalf("get after delete status = %d, want %d", missing.Code, http.StatusNotFound)
	}
}

func TestCreateTodoRejectsInvalidInput(t *testing.T) {
	t.Parallel()
	handler := (&server{store: newTodoStore()}).routes()

	response := request(t, handler, http.MethodPost, "/todos", `{"title":"", "unknown":true}`)
	if response.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusBadRequest)
	}

	response = request(t, handler, http.MethodPatch, "/todos/1", `{}`)
	if response.Code != http.StatusBadRequest {
		t.Fatalf("empty update status = %d, want %d", response.Code, http.StatusBadRequest)
	}
}

func request(t *testing.T, handler http.Handler, method, target, body string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(method, target, bytes.NewBufferString(body))
	if body != "" {
		req.Header.Set("Content-Type", "application/json")
	}
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, req)
	return response
}
