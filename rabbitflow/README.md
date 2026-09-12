# Rabbitflow

Rabbitflow is a small RabbitMQ and Go concurrency lab. A producer publishes
confirmed events to a durable queue. A consumer changes the number of worker
goroutines as the broker backlog changes. The browser dashboard shows the queue,
workers, throughput, and each scaling decision.

This borrows the observable flow of an RxJS pipeline. It is not an implementation
of RxJS operators or ReactiveX backpressure semantics.

## Run it

You need Docker Compose or Podman Compose.

```sh
cd rabbitflow
docker compose up --build
```

For Podman:

```sh
cd rabbitflow
podman compose up --build
```

Open <http://localhost:8080>. RabbitMQ's management UI is at
<http://localhost:15672> with username `demo` and password `demo`.

Stop the services while retaining RabbitMQ data:

```sh
docker compose down
```

Use the matching `podman compose down` command if you started it with Podman.
The Compose file binds all ports to localhost. Its credentials are only for this
local prototype.

## Try the scaling loop

1. Leave the pool at 2 to 16 workers and 8 events per worker.
2. Set work per event to 800 ms.
3. Send a burst of 120 events.
4. Watch RabbitMQ's ready count rise and the pool add workers.
5. When the queue drains, wait through the cooldown and watch the pool return to
   two workers.

The steady producer is useful for finding an equilibrium. A high publish rate or
long handler duration will keep a backlog and hold the pool near its upper bound.

## How it works

```text
dashboard ──HTTP──> producer ──confirmed publish──> durable RabbitMQ queue
     ▲                                                │
     │                                                │ prefetch 1
     └──── server-sent metrics ── scaler ── worker goroutines
                                                   │
                                           manual ack after work
```

Each worker owns one AMQP consumer channel with prefetch set to 1. This keeps
unclaimed work visible in RabbitMQ instead of buffering a large delivery batch in
the Go process. The monitor samples the queue every 500 ms and computes:

```text
desired = clamp(minWorkers, maxWorkers,
                ceil((readyMessages + busyWorkers) / eventsPerWorker))
```

Growth happens at the next sample. Lower demand must persist through the cooldown
before workers retire. Retiring workers finish an event they already started, but
they do not take a new one. The pool counts those retiring goroutines against the
maximum until they exit, so a quick scale-down followed by scale-up cannot exceed
the configured bound.

Rabbitflow uses publisher confirms for accepted publishes, persistent messages,
manual consumer acknowledgements, and a durable queue. If the broker connection
drops during processing, unacknowledged messages return to RabbitMQ for
redelivery. If a publish fails while its confirmation is uncertain, Rabbitflow
reports that event as uncertain and does not retry it. A production producer would
need stable event IDs plus an outbox or another deduplication-aware retry design.

## Useful commands

Run the Go checks without containers:

```sh
go test -race ./...
go vet ./...
go build -o ./bin/rabbitflow .
```

Inspect broker counts during a run:

```sh
docker compose exec rabbitmq \
  rabbitmqctl list_queues name durable messages_ready messages_unacknowledged consumers
```

The application accepts these environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `AMQP_URL` | `amqp://demo:demo@localhost:5672/` | RabbitMQ connection URL |
| `QUEUE_NAME` | `rabbitflow.events` | Durable work queue |
| `HTTP_ADDR` | `127.0.0.1:8080` | Dashboard and API listener |

The main API routes are `GET /api/state`, `GET /api/events`, `POST /api/burst`,
`POST /api/producer`, and `POST /api/pool`. The event stream uses server-sent
events, which keeps the UI dependency-free.
