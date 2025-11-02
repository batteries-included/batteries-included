package rage

import (
	"bi/pkg/access"
	"encoding/json"
	"fmt"
	"io"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type RageReport struct {
	InstallSlug  string
	KubeExists   bool
	PodsInfo     []PodRageInfo
	HttpRoutes   []HttpRouteRageInfo
	AccessSpec   *access.AccessSpec
	KindIPs      *string
	BILogs       map[string][]interface{}
	Nodes        []NodeRageInfo
	Metrics      map[string]interface{}
	ServicesInfo []ServiceRageInfo
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

type HttpRouteRageInfo struct {
	Namespace  string
	Name       string
	Hostnames  []string
	Conditions []metav1.Condition
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

type ServiceRageInfo struct {
	Namespace  string
	Name       string
	Type       string
	ClusterIPs []string
	Conditions []metav1.Condition
	Ingresses  []string
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
