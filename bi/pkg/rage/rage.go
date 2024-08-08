package rage

import (
	"bi/pkg/access"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

type RageReport struct {
	InstallSlug string
	KubeExists  bool
	PodsInfo    []PodRageInfo
	AccessSpec  *access.AccessSpec
	KindIPs     *string
	BILogs      map[string][]interface{}
}

type ContainerRageInfo struct {
	Name         string
	Running      bool
	RestartCount int
	Logs         string
}

type PodRageInfo struct {
	Namespace     string
	Name          string
	Phase         string
	Message       string
	ContainerInfo map[string]ContainerRageInfo
}

func (report *RageReport) Write(path string) error {
	// json serialize the report and write it to the path
	contents, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("unable to marshal rage report: %w", err)
	}

	// Make the rage directory if it doesn't exist
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return fmt.Errorf("unable to create rage directory: %w", err)
	}

	if err := os.WriteFile(path, contents, 0644); err != nil {
		return fmt.Errorf("unable to write rage report: %w", err)
	}
	return nil
}
