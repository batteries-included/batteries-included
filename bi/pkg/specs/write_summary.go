package specs

import (
	"encoding/json"
	"log/slog"
	"os"
)

func (spec *InstallSpec) WriteStateSummary(path string) error {
	contents, err := json.Marshal(spec.TargetSummary)
	if err != nil {
		return err
	}

	slog.Debug("Writing state summary to ", slog.String("path", path))
	return os.WriteFile(path, contents, 0o600)
}
