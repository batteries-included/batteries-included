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
	HttpRoutes  []HttpRouteRageInfo
	AccessSpec  *access.AccessSpec
	KindIPs     *string
	BILogs      map[string][]interface{}
	Nodes       []NodeRageInfo
	Metrics     map[string]interface{}
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
	Events        []PodEventRageInfo
}

type PodEventRageInfo struct {
	Type               string
	Reason             string
	Message            string
	FirstTimestamp     string
	LastTimestamp      string
	ReportingComponent string
}
type HttpRouteConditionRageInfo struct {
	LastTransitionTime string
	Message            string
	Reason             string
	Status             string
	Type               string
}
type HttpRouteRageInfo struct {
	Namespace  string
	Name       string
	Hostnames  []string
	Conditions []HttpRouteConditionRageInfo
}

type NodeConditionRageInfo struct {
	Type    string
	Status  string
	Message string
}

type NodeRageInfo struct {
	Name              string
	Cores             int32
	MemoryBytes       int64
	Conditions        []NodeConditionRageInfo
	KubernetesVersion string
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
