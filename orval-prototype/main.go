package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"
)

type Todo struct {
	ID        string    `json:"id"`
	Title     string    `json:"title"`
	Details   string    `json:"details"`
	Completed bool      `json:"completed"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

type createTodoInput struct {
	Title   string `json:"title"`
	Details string `json:"details"`
}

type updateTodoInput struct {
	Title     *string `json:"title"`
	Details   *string `json:"details"`
	Completed *bool   `json:"completed"`
}

type todoStore struct {
	mu     sync.RWMutex
	nextID int
	todos  map[string]Todo
}

func newTodoStore() *todoStore {
	return &todoStore{todos: make(map[string]Todo)}
}

func (s *todoStore) list() []Todo {
	s.mu.RLock()
	defer s.mu.RUnlock()

	todos := make([]Todo, 0, len(s.todos))
	for id := 1; id < s.nextID; id++ {
		if todo, ok := s.todos[strconv.Itoa(id)]; ok {
			todos = append(todos, todo)
		}
	}
	return todos
}

func (s *todoStore) create(input createTodoInput) Todo {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.nextID++
	now := time.Now().UTC()
	todo := Todo{
		ID:        strconv.Itoa(s.nextID),
		Title:     input.Title,
		Details:   input.Details,
		CreatedAt: now,
		UpdatedAt: now,
	}
	s.todos[todo.ID] = todo
	return todo
}

func (s *todoStore) get(id string) (Todo, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	todo, ok := s.todos[id]
	return todo, ok
}

func (s *todoStore) update(id string, input updateTodoInput) (Todo, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	todo, ok := s.todos[id]
	if !ok {
		return Todo{}, false
	}
	if input.Title != nil {
		todo.Title = *input.Title
	}
	if input.Details != nil {
		todo.Details = *input.Details
	}
	if input.Completed != nil {
		todo.Completed = *input.Completed
	}
	todo.UpdatedAt = time.Now().UTC()
	s.todos[id] = todo
	return todo, true
}

func (s *todoStore) delete(id string) bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.todos[id]; !ok {
		return false
	}
	delete(s.todos, id)
	return true
}

type server struct {
	store *todoStore
}

func main() {
	s := &server{store: newTodoStore()}
	addr := ":8080"
	log.Printf("todo API listening on http://localhost%s", addr)
	if err := http.ListenAndServe(addr, cors(s.routes())); err != nil {
		log.Fatal(err)
	}
}

func (s *server) routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", s.health)
	mux.HandleFunc("GET /todos", s.listTodos)
	mux.HandleFunc("POST /todos", s.createTodo)
	mux.HandleFunc("GET /todos/{id}", s.getTodo)
	mux.HandleFunc("PATCH /todos/{id}", s.updateTodo)
	mux.HandleFunc("DELETE /todos/{id}", s.deleteTodo)
	return cors(mux)
}

func (s *server) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (s *server) listTodos(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, s.store.list())
}

func (s *server) createTodo(w http.ResponseWriter, r *http.Request) {
	var input createTodoInput
	if err := decodeJSON(r, &input); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	input.Title = strings.TrimSpace(input.Title)
	if input.Title == "" {
		writeError(w, http.StatusBadRequest, "title is required")
		return
	}
	writeJSON(w, http.StatusCreated, s.store.create(input))
}

func (s *server) getTodo(w http.ResponseWriter, r *http.Request) {
	todo, ok := s.store.get(r.PathValue("id"))
	if !ok {
		writeError(w, http.StatusNotFound, "todo not found")
		return
	}
	writeJSON(w, http.StatusOK, todo)
}

func (s *server) updateTodo(w http.ResponseWriter, r *http.Request) {
	var input updateTodoInput
	if err := decodeJSON(r, &input); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if input.Title == nil && input.Details == nil && input.Completed == nil {
		writeError(w, http.StatusBadRequest, "provide at least one field to update")
		return
	}
	if input.Title != nil {
		trimmed := strings.TrimSpace(*input.Title)
		if trimmed == "" {
			writeError(w, http.StatusBadRequest, "title cannot be empty")
			return
		}
		input.Title = &trimmed
	}
	todo, ok := s.store.update(r.PathValue("id"), input)
	if !ok {
		writeError(w, http.StatusNotFound, "todo not found")
		return
	}
	writeJSON(w, http.StatusOK, todo)
}

func (s *server) deleteTodo(w http.ResponseWriter, r *http.Request) {
	if !s.store.delete(r.PathValue("id")) {
		writeError(w, http.StatusNotFound, "todo not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func decodeJSON(r *http.Request, destination any) error {
	decoder := json.NewDecoder(r.Body)
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(destination); err != nil {
		return fmt.Errorf("invalid JSON: %w", err)
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return errors.New("request body must contain one JSON value")
	}
	return nil
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(value); err != nil {
		log.Printf("write JSON response: %v", err)
	}
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}

func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PATCH, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
