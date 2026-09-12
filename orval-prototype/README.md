# Orval prototype

This folder contains a small Orval demo. The Go service keeps TODOs in memory, has no authentication, and resets every time it starts. The React frontend uses TanStack Router and TanStack Query, without TanStack Start.

It exposes these endpoints:

- `GET /health`
- `GET /todos` and `POST /todos`
- `GET /todos/{id}`, `PATCH /todos/{id}`, and `DELETE /todos/{id}`

`openapi.yaml` is the contract passed to Orval. Its operation IDs give generated functions stable names, and its schemas match the JSON returned by the Go handlers.

## Run it

Install Go 1.26.1 or newer, then run:

```sh
cd orval-prototype
go run .
```

The API listens on `http://localhost:8080`. CORS permits the local frontend.

Create and fetch a TODO:

```sh
curl -X POST http://localhost:8080/todos \
  -H 'Content-Type: application/json' \
  -d '{"title":"Try Orval","details":"Generate TanStack Query hooks next."}'

curl http://localhost:8080/todos
```

## Run the full prototype

Use two terminals in this folder. Start the API first:

```sh
PATH=/usr/local/go/bin:$PATH go run .
```

Then install the frontend dependencies and start Vite:

```sh
pnpm install
pnpm dev
```

Open `http://localhost:5173`. The frontend sends requests to `http://localhost:8080` through [src/api/axios-instance.ts](src/api/axios-instance.ts).

## Where Orval fits

`openapi.yaml` is the source contract. The command below regenerates [src/api/generated](src/api/generated), which includes the `Todo` TypeScript type, Axios request functions, and TanStack Query hooks such as `useListTodos` and `useCreateTodo`.

```sh
pnpm generate
```

The hand-written TODO screen at [src/routes/todos.tsx](src/routes/todos.tsx) imports those generated hooks and types. Do not edit files beneath `src/api/generated` by hand.

## Verification

This environment has `pnpm` 11.21.0 and Go 1.26.1 at `/usr/local/go/bin/go`. Use `PATH=/usr/local/go/bin:$PATH go test ./...` if Go is not already on your `PATH`.
