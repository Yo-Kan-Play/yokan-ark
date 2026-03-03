package main

import (
	"log"
	"os"
	"time"
)

type ActionLogger struct {
	base *log.Logger
}

func NewLogger() *ActionLogger {
	return &ActionLogger{base: log.New(os.Stdout, "[yokan-bot] ", log.LstdFlags|log.Lmsgprefix)}
}

func (l *ActionLogger) Info(msg string, args ...any) {
	l.base.Printf("INFO "+msg, args...)
}

func (l *ActionLogger) Warn(msg string, args ...any) {
	l.base.Printf("WARN "+msg, args...)
}

func (l *ActionLogger) Error(msg string, args ...any) {
	l.base.Printf("ERROR "+msg, args...)
}

func (l *ActionLogger) Action(mapID, action, result string, started time.Time) {
	elapsed := time.Since(started).Milliseconds()
	l.base.Printf("map_id=%s action=%s result=%s elapsed_ms=%d", mapID, action, result, elapsed)
}
