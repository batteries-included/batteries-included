package main

import (
	"log/slog"
	"os"
	"path/filepath"
	"time"

	"pastebin/server"

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

	staticPath := "/static/"
	indexPath := "index.html"
	if len(os.Args) > 1 {
		staticPath = filepath.Clean(os.Args[1])
	}

	if len(os.Args) > 2 {
		indexPath = filepath.Clean(os.Args[2])
	}

	motd := os.Getenv("MOTD")

	slog.Debug("Starting server",
		slog.String("staticPath", staticPath),
		slog.String("indexPath", indexPath))

	a := server.App{
		IndexPath:      indexPath,
		BaseStaticPath: staticPath,
		MOTD:           motd,
	}
	err := a.Initialize()
	if err != nil {
		panic(err)
	}
	a.Run(":8080")
}
