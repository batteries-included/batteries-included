package util

import (
	"context"
	"log/slog"
	"strings"

	"github.com/pulumi/pulumi/sdk/v3/go/auto/events"
	"github.com/vbauerster/mpb/v8"
	"github.com/vbauerster/mpb/v8/decor"
)

// ProgressReporter is a convenience wrapper around mpb.Progress.
type ProgressReporter struct {
	progress *mpb.Progress
}

// NewProgressReporter creates a new ProgressReporter.
func NewProgressReporter() *ProgressReporter {
	return &ProgressReporter{
		progress: mpb.New(),
	}
}

// Shutdown stops all registered progress bars.
func (pr *ProgressReporter) Shutdown() {
	pr.progress.Shutdown()
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

// ForGPUSetup creates a new progress bar for GPU setup operations.
func (pr *ProgressReporter) ForGPUSetup() *mpb.Bar {
	return pr.progress.AddBar(4,
		mpb.PrependDecorators(
			decor.Name("gpu setup", decor.WC{C: decor.DindentRight | decor.DextraSpace}),
		),
		mpb.AppendDecorators(
			decor.Percentage(),
		),
	)
}

// ForBootstrapProgress creates a new progress bar for bootstrap operations.
func (pr *ProgressReporter) ForBootstrapProgress() *mpb.Bar {
	return pr.progress.AddBar(7,
		mpb.PrependDecorators(
			decor.Name("bootstrap", decor.WC{C: decor.DindentRight | decor.DextraSpace}),
		),
		mpb.AppendDecorators(
			decor.Percentage(),
		),
	)
}

// ForInitialSync creates a new progress bar for initial resource sync.
func (pr *ProgressReporter) ForInitialSync() *mpb.Bar {
	return pr.progress.AddBar(0, // Will be updated as we discover resources
		mpb.PrependDecorators(
			decor.Name("sync", decor.WC{C: decor.DindentRight | decor.DextraSpace}),
		),
		mpb.AppendDecorators(
			decor.Percentage(),
		),
	)
}

// ForHealthCheck creates a new progress bar for HTTP health check operations.
func (pr *ProgressReporter) ForHealthCheck() *mpb.Bar {
	return pr.progress.AddBar(10, // retry attempts
		mpb.PrependDecorators(
			decor.Name("health check", decor.WC{C: decor.DindentRight | decor.DextraSpace}),
		),
		mpb.AppendDecorators(
			decor.Percentage(),
		),
	)
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

// IncrementWithMessage increments a progress bar and logs a message
func IncrementWithMessage(bar *mpb.Bar, message string) {
	if bar != nil {
		bar.Increment()
		slog.Info(message)
	}
}

// SetTotalAndComplete sets the total for a progress bar and marks it complete
func SetTotalAndComplete(bar *mpb.Bar) {
	if bar != nil {
		bar.SetTotal(bar.Current(), true)
	}
}
