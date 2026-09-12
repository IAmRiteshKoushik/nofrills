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

## One backend, web and mobile clients

One OpenAPI document can serve separate web and mobile repositories. Tag each operation by its domain and intended client, then have each repository run Orval with a tag filter. Keep the domain tag first when using `tags-split`, because Orval uses the first tag for the generated file grouping.

```yaml
paths:
  /todos:
    get:
      tags: [todos, web]
      operationId: listTodos
  /mobile/sync:
    get:
      tags: [sync, mobile]
      operationId: getMobileSync
  /profile:
    get:
      tags: [profile, web, mobile]
      operationId: getProfile
```

In the web repository, generate only `web` operations:

```ts
import { defineConfig } from 'orval'

export default defineConfig({
  webApi: {
    input: {
      target: './openapi.yaml',
      filters: { tags: ['web'] },
    },
    output: {
      mode: 'tags-split',
      target: './src/api/generated/api.ts',
      schemas: './src/api/generated/models',
      client: 'react-query',
      httpClient: 'axios',
    },
  },
})
```

The mobile repository uses the same shape with `filters: { tags: ['mobile'] }`. Orval includes the schemas those selected operations reference, so each client avoids unrelated endpoint code and models. Tag filtering affects generation only. The backend must still enforce authorization and client access rules.

Useful project locations:

- [OpenAPI contract](openapi.yaml)
- [Current Orval configuration](orval.config.ts)
- [Generated API client folder](src/api/generated/)
- [Hand-written TODO route](src/routes/todos.tsx)

## Verification

This environment has `pnpm` 11.21.0 and Go 1.26.1 at `/usr/local/go/bin/go`. Use `PATH=/usr/local/go/bin:$PATH go test ./...` if Go is not already on your `PATH`.
