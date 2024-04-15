package specs

import (
	"bi/pkg/kube"
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
		return err
	}

	slog.Debug("Writing state summary to ", slog.String("path", path))
	return os.WriteFile(path, contents, 0o600)
}

func (spec *InstallSpec) WriteSummaryToKube(kubeClient kube.KubeClient) error {
	contents, err := json.Marshal(spec.TargetSummary)
	if err != nil {
		return err
	}

	ns, err := coreNamespace(spec.TargetSummary.Batteries, "battery_core")
	if err != nil {
		return err
	}

	if err := kubeClient.EnsureResourceExists(map[string]any{
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
		return err
	}

	return nil
}

func coreNamespace(batteries []BatterySpec, typ string) (string, error) {
	ix := slices.IndexFunc(batteries, func(bs BatterySpec) bool { return bs.Type == typ })
	if ix < 0 {
		return "", fmt.Errorf("failed to find core namespace")
	}

	return batteries[ix].Config["core_namespace"].(string), nil
}
