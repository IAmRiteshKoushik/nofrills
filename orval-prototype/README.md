# Orval prototype API

This folder contains the API half of a small Orval demo. The service keeps TODOs in memory, has no authentication, and resets every time it starts.

It exposes these endpoints:

- `GET /health`
- `GET /todos` and `POST /todos`
- `GET /todos/{id}`, `PATCH /todos/{id}`, and `DELETE /todos/{id}`

`openapi.yaml` is the contract that the later frontend will pass to Orval. Its operation IDs give generated functions stable names, and its schemas match the JSON returned by the Go handlers.

## Run it

Install Go 1.24 or newer, then run:

```sh
cd orval-prototype
go run .
```

The API listens on `http://localhost:8080`. CORS permits a separate local frontend during the next step.

Create and fetch a TODO:

```sh
curl -X POST http://localhost:8080/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"Try Orval","details":"Generate TanStack Query hooks next."}'

curl http://localhost:8080/todos
```

For now, the API itself has no Node dependencies. We will add the frontend and its Orval configuration inside this same folder next.

## Verification

This environment has `pnpm` 11.21.0 but no `go` command, so the Go formatter and tests could not run here. Once Go is installed, run `go test ./...` before moving on to the frontend.
