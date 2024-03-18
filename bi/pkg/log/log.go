package log

import (
	"log/slog"
	"os"
	"time"

	"github.com/lmittmann/tint"
)

func SetupLogging(levelString string, color bool) error {
	var logLevel slog.Level

	w := os.Stderr

	err := logLevel.UnmarshalText([]byte(levelString))
	if err != nil {
		return err
	}

	slog.SetDefault(slog.New(
		tint.NewHandler(w, &tint.Options{
			Level:      logLevel,
			AddSource:  logLevel == slog.LevelDebug,
			NoColor:    !color,
			TimeFormat: time.Kitchen,
		}),
	))

	return nil
}
