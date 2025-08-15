package registry

import (
	"testing"
	"time"
)

func TestCalculateDelay(t *testing.T) {
	tests := []struct {
		name        string
		delay       time.Duration
		jitter      time.Duration
		expectedMin time.Duration
		expectedMax time.Duration
	}{
		{
			name:        "no delay",
			delay:       0,
			jitter:      0,
			expectedMin: 0,
			expectedMax: 0,
		},
		{
			name:        "delay without jitter",
			delay:       1 * time.Second,
			jitter:      0,
			expectedMin: 1 * time.Second,
			expectedMax: 1 * time.Second,
		},
		{
			name:        "delay with jitter",
			delay:       1 * time.Second,
			jitter:      200 * time.Millisecond,
			expectedMin: 0, // Could be reduced to 0 due to negative jitter
			expectedMax: 1200 * time.Millisecond,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			updater := &RegistryUpdater{
				delay:  tt.delay,
				jitter: tt.jitter,
			}

			// Test multiple times to account for randomness
			for i := 0; i < 10; i++ {
				result := updater.calculateDelay()

				if result < tt.expectedMin {
					t.Errorf("calculateDelay() = %v, expected >= %v", result, tt.expectedMin)
				}
				if result > tt.expectedMax {
					t.Errorf("calculateDelay() = %v, expected <= %v", result, tt.expectedMax)
				}
			}
		})
	}
}

func TestNewRegistryUpdaterWithDelay(t *testing.T) {
	registry := NewRegistry()
	ignoredImages := []string{"test/image"}
	delay := 1 * time.Second
	jitter := 200 * time.Millisecond
	maxFailures := 5

	updater := NewRegistryUpdaterWithDelay(registry, ignoredImages, delay, jitter, maxFailures)

	if updater.delay != delay {
		t.Errorf("expected delay %v, got %v", delay, updater.delay)
	}
	if updater.jitter != jitter {
		t.Errorf("expected jitter %v, got %v", jitter, updater.jitter)
	}
	if updater.maxFailures != maxFailures {
		t.Errorf("expected maxFailures %v, got %v", maxFailures, updater.maxFailures)
	}
	if len(updater.ignoredList) != 1 || updater.ignoredList[0] != "test/image" {
		t.Errorf("expected ignoredList [test/image], got %v", updater.ignoredList)
	}
}

func TestNewRegistryUpdater(t *testing.T) {
	registry := NewRegistry()
	ignoredImages := []string{"test/image"}
	maxFailures := 3

	updater := NewRegistryUpdater(registry, ignoredImages, maxFailures)

	if updater.delay != 0 {
		t.Errorf("expected delay 0, got %v", updater.delay)
	}
	if updater.jitter != 0 {
		t.Errorf("expected jitter 0, got %v", updater.jitter)
	}
	if updater.maxFailures != maxFailures {
		t.Errorf("expected maxFailures %v, got %v", maxFailures, updater.maxFailures)
	}
	if len(updater.ignoredList) != 1 || updater.ignoredList[0] != "test/image" {
		t.Errorf("expected ignoredList [test/image], got %v", updater.ignoredList)
	}
}
