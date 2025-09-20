package rage

import (
	"bi/pkg/access"
	"encoding/json"
	"fmt"
	"io"
)

type RageReport struct {
	InstallSlug     string
	KubeExists      bool
	PodsInfo        []PodRageInfo
	HttpRoutes      []HttpRouteRageInfo
	AccessSpec      *access.AccessSpec
	KindIPs         *string
	BILogs          map[string][]interface{}
	Nodes           []NodeRageInfo
	ControllerState ControllerStateRageInfo
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
	Conditions    []ConditionRageInfo
	ContainerInfo map[string]ContainerRageInfo
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

type ConditionRageInfo struct {
	Type    string
	Status  string
	Message string
}

type NodeRageInfo struct {
	Name              string
	Cores             int32
	MemoryBytes       int64
	Conditions        []ConditionRageInfo
	KubernetesVersion string
}

type ControllerStateRageInfo struct {
	AgeSeconds          int64 `json:"age_seconds"`
	Batteries           int   `json:"batteries"`
	PostgresClusters    int   `json:"postgres_clusters"`
	FerretServices      int   `json:"ferret_services"`
	RedisInstances      int   `json:"redis_instances"`
	Notebooks           int   `json:"notebooks"`
	KnativeServices     int   `json:"knative_services"`
	TraditionalServices int   `json:"traditional_services"`
	IPAddressPools      int   `json:"ip_address_pools"`
	Projects            int   `json:"projects"`
	ModelInstances      int   `json:"model_instances"`

	Pods         int `json:"pods"`
	Services     int `json:"services"`
	Deployments  int `json:"deployments"`
	StatefulSets int `json:"stateful_sets"`
	Nodes        int `json:"nodes"`

	Realms int `json:"realms"`
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
