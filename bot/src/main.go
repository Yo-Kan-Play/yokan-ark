package main

import (
	"context"
	"flag"
	"fmt"
	"os"
)

func main() {
	configPath := flag.String("config", "/config/config.yaml", "config.yaml path")
	checkOnly := flag.Bool("check-config", false, "validate config and exit")
	flag.Parse()

	logger := NewLogger()
	cfg, err := LoadConfig(*configPath)
	if err != nil {
		logger.Error("設定エラー: %v", err)
		os.Exit(1)
	}
	if *checkOnly {
		fmt.Println("config ok")
		return
	}
	bot, err := NewBot(cfg, *configPath, logger)
	if err != nil {
		logger.Error("Bot初期化失敗: %v", err)
		os.Exit(1)
	}
	if err := bot.Run(context.Background()); err != nil {
		logger.Error("Bot終了: %v", err)
		os.Exit(1)
	}
}
