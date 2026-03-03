FROM docker.io/library/golang:1.22-bookworm AS build

WORKDIR /src
COPY src/go.mod src/go.sum* ./
RUN go mod download

COPY src/ ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/yokan-ark-bot .

FROM docker.io/library/debian:bookworm-slim

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates tzdata \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /out/yokan-ark-bot /usr/local/bin/yokan-ark-bot
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/yokan-ark-bot

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
