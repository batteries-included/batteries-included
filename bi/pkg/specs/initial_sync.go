package specs

import (
	"log/slog"
	"time"

	"bi/pkg/kube"
)

func (installSpec *InstallSpec) InitialSync(kubeClient kube.KubeClient) error {
	var savedErr error = nil
	for attempt := 0; attempt < 7; attempt++ {
		savedErr = nil
		for resourceName, resource := range installSpec.InitialResources {
			slog.Debug("Ensuring resource exists in target kubernetes cluster",
				slog.String("resourceName", resourceName))
			err := kubeClient.EnsureResourceExists(resource)

			if err != nil {
				slog.Debug("Expected error while ensuring",
					slog.Int("attempt", attempt),
					slog.Any("error", err))
				savedErr = err
				continue
			}
		}
		if savedErr == nil {
			slog.Info("Initial sync complete", slog.Int("attempt", attempt))
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
