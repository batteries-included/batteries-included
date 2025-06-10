package log

import (
	"fmt"
	"log/slog"
	"os"

	"github.com/lmittmann/tint"
)

// Level is the current verbosity level of the logger.
var Level slog.Level

// SetupLogging configures the default slog Logger with the given verbosity and
// color settings.
func SetupLogging(verbosity string, color bool) error {
	if err := Level.UnmarshalText([]byte(verbosity)); err != nil {
		return fmt.Errorf("unable to parse log level: %w", err)
	}

	slog.SetDefault(slog.New(tint.NewHandler(os.Stderr, &tint.Options{
		Level:      Level,
		AddSource:  Level == slog.LevelDebug,
		NoColor:    !color,
		TimeFormat: "15:04:05.000",
	})))

	return nil
}
