FROM docker.io/library/golang:1.25-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -o /rabbitflow .

FROM docker.io/library/alpine:3.22
RUN apk add --no-cache ca-certificates
COPY --from=build /rabbitflow /usr/local/bin/rabbitflow
USER 65532:65532
ENV HTTP_ADDR=0.0.0.0:8080
EXPOSE 8080
ENTRYPOINT ["rabbitflow"]
