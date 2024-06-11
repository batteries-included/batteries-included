package util

import (
	"github.com/pulumi/pulumi/sdk/v3/go/auto/events"
	"github.com/vbauerster/mpb/v8"
	"github.com/vbauerster/mpb/v8/decor"
)

// Progress is a helper for creating progress bars for Pulumi operations.
type Progress struct {
	progress *mpb.Progress
}

// NewProgress creates a new Progress instance.
func NewProgress() *Progress {
	return &Progress{
		progress: mpb.New(),
	}
}

// Shutdown stops all registered progress bars.
func (p *Progress) Shutdown() {
	p.progress.Shutdown()
}

// AddBar creates a new progress bar with the given name and initial total.
// The returns events channel can be passed to pulumi via optup.EventStreams()
// and optdestroy.EventStreams().
func (p *Progress) AddBar(name string, destroy bool) chan<- events.EngineEvent {
	bar := p.progress.AddBar(0,
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
