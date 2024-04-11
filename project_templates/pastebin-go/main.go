package main

import (
	"log/slog"
	"os"
	"pastebin/server"
	"time"

	"github.com/lmittmann/tint"
)

func main() {
	// Setup logging
	slog.SetDefault(slog.New(
		tint.NewHandler(os.Stderr, &tint.Options{
			Level:      slog.LevelDebug,
			TimeFormat: time.Kitchen,
			NoColor:    false,
		}),
	))

	a := server.App{}
	err := a.Initialize()
	if err != nil {
		panic(err)
	}
	a.Run(":8080")
}
