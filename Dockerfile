# ---------- Stage 1: build ----------
FROM golang:1.23-alpine AS builder

WORKDIR /app

# Copy module files first so dependency layers are cached
COPY go.mod ./
RUN go mod download

COPY . .

# Static Linux binary, symbols stripped for a smaller size
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w" -o server .

# ---------- Stage 2: runtime ----------
FROM alpine:3.20

# Run as a non-root user
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /app/server .
USER app

ENV PORT=9090
EXPOSE 9090

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["./server"]
