package rage

import (
	"bi/pkg/access"
	"encoding/json"
	"fmt"
	"io"
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

func (report *RageReport) Write(w io.Writer) error {
	// json serialize the report and write it to the path
	contents, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return fmt.Errorf("unable to marshal rage report: %w", err)
	}

	_, err = w.Write(contents)
	if err != nil {
		return fmt.Errorf("unable to write rage contents: %w", err)
	}

	return nil
}
