# go-docker-app

A small HTTP server written with Go's standard library and packaged with Docker.

## Files

| File | Purpose |
|------|---------|
| `main.go` | Server code: handlers, config, graceful shutdown |
| `go.mod` | Go module name and Go version (no dependencies) |
| `Dockerfile` | Multi-stage build: compile in `golang:alpine`, run in slim `alpine` |
| `.dockerignore` | Keeps unneeded files out of the Docker build context |
| `README.md` | This documentation |

## Endpoints (GET only)

| Route | Response |
|-------|----------|
| `/` | `Hello! Brother.\nHere I practice Jenkins..` |
| `/api` | `{"message":"Hello from Go API!","status":"success"}` |
| `/health` | `OK` (200) |

Other methods return `405`, unknown paths return `404`.

## Configuration

`PORT` sets the listening port (`9090`).

## Run locally

    go run .

## Build a Linux executable

    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o server .

## Docker

    docker build -t go-docker-app .
    docker run --rm -p 9090:9090 go-docker-app

Test:

    curl -i http://localhost:9090/
    curl -i http://localhost:9090/api
    curl -i http://localhost:9090/health
    curl -i -X POST http://localhost:9090/api   # 405

Stop with `docker stop <container>`; the server shuts down gracefully on SIGTERM.
