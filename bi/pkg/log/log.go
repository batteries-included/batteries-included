package log

import (
	"fmt"
	"log/slog"
	"os"
	"path/filepath"

	"github.com/lmittmann/tint"
	slogmulti "github.com/samber/slog-multi"
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

// CollectDebugLogs configures the default slog Logger to write a JSON debug log
// file to the given path (in addition to stderr).
func CollectDebugLogs(debugLogPath string) error {
	if err := os.MkdirAll(filepath.Dir(debugLogPath), 0o700); err != nil {
		return fmt.Errorf("unable to create debug log directory: %w", err)
	}

	debugLogFile, err := os.OpenFile(debugLogPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("unable to open debug log file: %w", err)
	}

	slog.SetDefault(slog.New(slogmulti.Fanout(
		slog.Default().Handler(),
		slog.NewJSONHandler(debugLogFile, &slog.HandlerOptions{
			Level:     slog.LevelDebug,
			AddSource: true,
		}),
	)))

	return nil
}
