package util

import (
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
