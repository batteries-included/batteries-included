package util

import (
	"context"
	"log/slog"
	"strings"
	"sync"

	"github.com/pulumi/pulumi/sdk/v3/go/auto/events"
	"github.com/vbauerster/mpb/v8"
	"github.com/vbauerster/mpb/v8/decor"
)

// ProgressReporter is a convenience wrapper around mpb.Progress.
type ProgressReporter struct {
	progress     *mpb.Progress
	shutdownOnce sync.Once
}

// NewProgressReporter creates a new ProgressReporter.
func NewProgressReporter() *ProgressReporter {
	return &ProgressReporter{
		progress: mpb.New(),
	}
}

// Shutdown stops all registered progress bars.
func (pr *ProgressReporter) Shutdown() {
	pr.shutdownOnce.Do(pr.progress.Shutdown)
}

// ForPulumiEvents creates a new progress bar for Pulumi events. The returned
// events channel can be passed to pulumi via optup.EventStreams() and optdestroy.EventStreams().
func (pr *ProgressReporter) ForPulumiEvents(name string, destroy bool) chan<- events.EngineEvent {
	bar := pr.progress.AddBar(0,
		mpb.PrependDecorators(
			decor.Name(name, decor.WC{C: decor.DindentRight | decor.DextraSpace}),
		),
		mpb.AppendDecorators(
			decor.Percentage(),
		),
	)

	// Pulumi will close the events channel when no more events are available.
	events := make(chan events.EngineEvent)
	go func() {
		var total int64
		for event := range events {
			if event.ResourcePreEvent != nil {
				total++
				bar.SetTotal(total, false)
			} else if !destroy && event.ResOutputsEvent != nil {
				bar.Increment()
			} else if destroy && event.CancelEvent != nil { // Somehow cancel also means (the operation completed).
				bar.Increment()
			}
		}

		// Ensure the bar is at 100% when done.
		bar.SetTotal(bar.Current(), true)
	}()

	return events
}

// ForKindCreateLogs creates a new progress bar for kind cluster creation logs.
func (pr *ProgressReporter) ForKindCreateLogs() slog.Handler {
	bar := pr.progress.AddBar(6,
		mpb.PrependDecorators(
			decor.Name("cluster", decor.WC{C: decor.DindentRight | decor.DextraSpace}),
		),
		mpb.AppendDecorators(
			decor.Percentage(),
		),
	)

	return &logInterceptor{
		bar: bar,
		// Six total steps in the kind cluster creation process.
		messages: []string{
			"Ensuring node image",
			"Preparing nodes",
			"Writing configuration",
			"Starting controlplane",
			"Installing CNI",
			"Installing StorageClass",
		},
	}
}

type logInterceptor struct {
	bar      *mpb.Bar
	messages []string
}

func (h *logInterceptor) Close() error {
	h.bar.SetTotal(h.bar.Current(), true)
	return nil
}

func (h *logInterceptor) Enabled(_ context.Context, _ slog.Level) bool { return true }

func (h *logInterceptor) Handle(_ context.Context, r slog.Record) error {
	for _, msg := range h.messages {
		if strings.Contains(r.Message, msg) {
			h.bar.Increment()
			break
		}
	}

	return nil
}

func (h *logInterceptor) WithAttrs(_ []slog.Attr) slog.Handler { return h }

func (h *logInterceptor) WithGroup(_ string) slog.Handler { return h }
