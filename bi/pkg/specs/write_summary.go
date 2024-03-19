package specs

import (
	"log/slog"
	"os"
)

func (spec *InstallSpec) WriteStateSummary(path string) error {
	contents, err := spec.TargetSummary.UnmarshalJSON()
	if err != nil {
		return err
	}

	slog.Debug("Writing state summary to ", slog.String("path", path))
	return os.WriteFile(path, contents, 0644)
}
