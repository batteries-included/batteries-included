package util

import (
	"bufio"
	"context"
	"io"
	"log/slog"
	"strings"
)

type logWriter struct {
	io.Writer
}

// DebugLogWriter creates a new io.Writer that logs each nnon-empty line written
// to it at debug level.
func DebugLogWriter(ctx context.Context, logger *slog.Logger) io.Writer {
	pr, pw := io.Pipe()
	go func() {
		<-ctx.Done()

		if err := pw.Close(); err != nil {
			logger.Error("Failed to close debug log writer", slog.Any("error", err))
		}
	}()

	go func() {
		scanner := bufio.NewScanner(pr)
		for scanner.Scan() {
			msg := strings.TrimSpace(scanner.Text())
			if msg != "" {
				logger.Debug(msg)
			}
		}
		if err := scanner.Err(); err != nil {
			logger.Error("Failed to read from debug log writer", slog.Any("error", err))
		}
	}()

	return &logWriter{Writer: pw}
}
