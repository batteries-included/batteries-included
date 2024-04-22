package specs

import (
	"bi/pkg/kube"
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log/slog"
	"os"
	"slices"
)

func (spec *InstallSpec) WriteStateSummary(path string) error {
	contents, err := json.Marshal(spec.TargetSummary)
	if err != nil {
		return fmt.Errorf("unable to marshal state summary: %w", err)
	}

	slog.Debug("Writing state summary to ", slog.String("path", path))
	if err := os.WriteFile(path, contents, 0o600); err != nil {
		return fmt.Errorf("unable to write state summary: %w", err)
	}

	return nil
}

func (spec *InstallSpec) WriteSummaryToKube(ctx context.Context, kubeClient kube.KubeClient) error {
	contents, err := json.Marshal(spec.TargetSummary)
	if err != nil {
		return fmt.Errorf("unable to marshal state summary: %w", err)
	}

	ns, err := coreNamespace(spec.TargetSummary.Batteries, "battery_core")
	if err != nil {
		return fmt.Errorf("unable to find battery_core namespace: %w", err)
	}

	if err := kubeClient.EnsureResourceExists(ctx, map[string]any{
		"apiVersion": "v1",
		"kind":       "Secret",
		"metadata": map[string]any{
			"name":      "initial-target-summary",
			"namespace": ns,
		},
		"type": "Opaque",
		"data": map[string]string{
			"summary.json": base64.StdEncoding.EncodeToString(contents),
		},
	}); err != nil {
		return fmt.Errorf("unable to write state summary to cluster: %w", err)
	}

	return nil
}

func coreNamespace(batteries []BatterySpec, typ string) (string, error) {
	ix := slices.IndexFunc(batteries, func(bs BatterySpec) bool { return bs.Type == typ })
	if ix < 0 {
		return "", fmt.Errorf("failed to find core namespace with type %s", typ)
	}

	return batteries[ix].Config["core_namespace"].(string), nil
}
