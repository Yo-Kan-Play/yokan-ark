package main

import (
	"context"
	"fmt"
	"strings"

	"github.com/gorcon/rcon"
)

type RCONClient struct {
	cfg *Config
}

func NewRCONClient(cfg *Config) *RCONClient {
	return &RCONClient{cfg: cfg}
}

func (r *RCONClient) password() string {
	return strings.TrimSpace(getEnv(r.cfg.Server.RCONPasswordEnv, ""))
}

func (r *RCONClient) addr(port int) string {
	return fmt.Sprintf("%s:%d", r.cfg.Server.RCONHost, port+r.cfg.Server.RCONPortOffset)
}

func (r *RCONClient) execute(ctx context.Context, mapPort int, cmd string) (string, error) {
	pass := r.password()
	if pass == "" {
		return "", fmt.Errorf("RCONパスワード未設定: env=%s", r.cfg.Server.RCONPasswordEnv)
	}
	conn, err := rcon.Dial(r.addr(mapPort), pass)
	if err != nil {
		return "", err
	}
	defer conn.Close()
	ch := make(chan struct {
		resp string
		err  error
	}, 1)
	go func() {
		resp, err := conn.Execute(cmd)
		ch <- struct {
			resp string
			err  error
		}{resp: resp, err: err}
	}()
	select {
	case <-ctx.Done():
		return "", ctx.Err()
	case out := <-ch:
		return out.resp, out.err
	}
}

func (r *RCONClient) SaveWorld(ctx context.Context, m MapConfig) error {
	_, err := r.execute(ctx, m.Port, "saveworld")
	return err
}

func (r *RCONClient) Broadcast(ctx context.Context, m MapConfig, msg string) error {
	msg = strings.ReplaceAll(msg, "\n", " ")
	_, err := r.execute(ctx, m.Port, "ServerChat "+msg)
	return err
}

func parsePlayers(raw string) []string {
	lines := strings.Split(raw, "\n")
	out := make([]string, 0, len(lines))
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" {
			continue
		}
		out = append(out, line)
	}
	return out
}

func (r *RCONClient) ListPlayers(ctx context.Context, m MapConfig) ([]string, error) {
	raw, err := r.execute(ctx, m.Port, "ListPlayers")
	if err != nil {
		return nil, err
	}
	return parsePlayers(raw), nil
}
