package log

import (
	"fmt"
	"log/slog"
	"os"
	"time"

	"github.com/lmittmann/tint"
)

func SetupLogging(levelString string, color bool) error {
	var logLevel slog.Level

	w := os.Stderr

	if err := logLevel.UnmarshalText([]byte(levelString)); err != nil {
		return fmt.Errorf("unable to parse log level: %w", err)
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
