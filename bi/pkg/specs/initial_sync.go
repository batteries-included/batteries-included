package specs

import (
	"bi/pkg/cluster/util"
	"bi/pkg/kube"
	"context"
	"log/slog"
	"time"

	"github.com/vbauerster/mpb/v8"
)

func (installSpec *InstallSpec) InitialSync(ctx context.Context, kubeClient kube.KubeClient, progressReporter *util.ProgressReporter) error {
	var syncBar *mpb.Bar
	if progressReporter != nil {
		syncBar = progressReporter.ForInitialSync()
		// Set total to the number of resources we need to sync
		syncBar.SetTotal(int64(len(installSpec.InitialResources)), false)
	}

	var savedErr error = nil
	for attempt := 0; attempt < 7; attempt++ {
		savedErr = nil
		resourceCount := 0
		for resourceName, resource := range installSpec.InitialResources {
			slog.Debug("Ensuring resource exists in target kubernetes cluster",
				slog.String("resourceName", resourceName))
			err := kubeClient.EnsureResourceExists(ctx, resource)

			if err != nil {
				slog.Debug("Expected error while ensuring",
					slog.Int("attempt", attempt),
					slog.Any("error", err))
				savedErr = err
				continue
			}
			resourceCount++
			if syncBar != nil {
				syncBar.SetCurrent(int64(resourceCount))
			}
		}
		if savedErr == nil {
			slog.Info("Initial sync complete", slog.Int("attempt", attempt))
			util.SetTotalAndComplete(syncBar)
			return nil
		}

		slog.Debug("Initial sync failed", slog.Int("attempt", attempt))
		// Sleep for 5 seconds multiplied by the attempt number
		// to give the cluster time to start
		time.Sleep(time.Duration(5*(attempt+1)) * time.Second)
	}

	if savedErr != nil {
		return savedErr
	}

	return nil
}
