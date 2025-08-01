package kind

import (
	"fmt"
	"log/slog"
	"regexp"
	"strings"

	"sigs.k8s.io/kind/pkg/log"
)

var _ log.Logger = (*slogAdapter)(nil)

func NewKindLogger(logger *slog.Logger) log.Logger {
	return &slogAdapter{Logger: logger}
}

type slogAdapter struct {
	*slog.Logger
}

func (l *slogAdapter) Warn(msg string) {
	l.Logger.Warn(stripLogMessage(msg))
}

func (l *slogAdapter) Warnf(format string, args ...any) {
	l.Logger.Warn(stripLogMessage(fmt.Sprintf(format, args...)))
}

func (l *slogAdapter) Error(msg string) {
	l.Logger.Error(stripLogMessage(msg))
}

func (l *slogAdapter) Errorf(format string, args ...any) {
	l.Logger.Error(stripLogMessage(fmt.Sprintf(format, args...)))
}

func (l *slogAdapter) V(_ log.Level) log.InfoLogger {
	return &slogInfoLogger{
		Logger: l.Logger,
	}
}

var _ log.InfoLogger = (*slogInfoLogger)(nil)

type slogInfoLogger struct {
	*slog.Logger
}

func (l *slogInfoLogger) Info(msg string) {
	l.Debug(stripLogMessage(msg))
}

func (l *slogInfoLogger) Infof(format string, args ...any) {
	l.Debug(stripLogMessage(fmt.Sprintf(format, args...)))
}

func (l *slogInfoLogger) Enabled() bool {
	return true
}

// KinD puts all kinds of "cute" emojis and such in its logs.
var stripEmojiRegexp = regexp.MustCompile(`[\p{So}\p{Pd}\x{2022}\x{25CF}]`)

func stripLogMessage(msg string) string {
	msg = stripEmojiRegexp.ReplaceAllString(msg, "")
	msg = strings.ReplaceAll(msg, "...", "")
	return strings.TrimSpace(msg)
}
