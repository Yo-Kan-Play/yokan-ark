package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func getEnv(key, fallback string) string {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return fallback
	}
	return v
}

func boolPtr(v bool) *bool {
	return &v
}

func bytesToHuman(n int64) string {
	if n <= 0 {
		return "0 B"
	}
	units := []string{"B", "KB", "MB", "GB", "TB"}
	value := float64(n)
	u := 0
	for value >= 1024 && u < len(units)-1 {
		value /= 1024
		u++
	}
	return fmt.Sprintf("%.1f %s", value, units[u])
}

func mustJSTNow() time.Time {
	loc, err := time.LoadLocation("Asia/Tokyo")
	if err != nil {
		return time.Now()
	}
	return time.Now().In(loc)
}

func parseHHMM(hhmm string, base time.Time) (time.Time, error) {
	loc := base.Location()
	t, err := time.ParseInLocation("15:04", hhmm, loc)
	if err != nil {
		return time.Time{}, err
	}
	return time.Date(base.Year(), base.Month(), base.Day(), t.Hour(), t.Minute(), 0, 0, loc), nil
}

func weekdayMatch(weekdays []string, t time.Time) bool {
	if len(weekdays) == 0 {
		return true
	}
	cur := strings.ToLower(t.Weekday().String()[:3])
	for _, w := range weekdays {
		if strings.ToLower(strings.TrimSpace(w)) == cur {
			return true
		}
	}
	return false
}

func ensureDir(path string) error {
	return os.MkdirAll(filepath.Clean(path), 0o755)
}
