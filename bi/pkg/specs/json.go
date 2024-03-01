package specs

import (
	"encoding/json"
	"fmt"
)

type KubeClusterSpec struct {
	Provider string `json:"provider"`
}

type BatterySpec struct {
	Group string `json:"group"`

	Type string `json:"type"`

	Config map[string]any `json:"config"`

	ID string `json:"id"`

	InsertedAt string `json:"inserted_at"`
	UpdatedAt  string `json:"updated_at"`
}

type IPAddressPoolSpec struct {
	Name   string `json:"name"`
	Subnet string `json:"subnet"`

	ID string `json:"id"`

	InsertedAt string `json:"inserted_at"`
	UpdatedAt  string `json:"updated_at"`
}

type StateSummarySpec struct {
	Batteries        []BatterySpec       `json:"batteries"`
	IPAddressPools   []IPAddressPoolSpec `json:"ip_address_pools"`
	KnativeServices  []map[string]any    `json:"knative_services"`
	Notebooks        []map[string]any    `json:"notebooks"`
	PostgresClusters []map[string]any    `json:"postgres_clusters"`
	FerretServices   []map[string]any    `json:"ferret_services"`
	RedisClusters    []map[string]any    `json:"redis_clusters"`
}

type InstallSpec struct {
	InitialResources map[string]any   `json:"initial_resources"`
	KubeCluster      KubeClusterSpec  `json:"kube_cluster"`
	TargetSummary    StateSummarySpec `json:"target_summary"`
}

const ParseErrorMessage = "Failed to parse install spec"

func UnmarshalJSON(data []byte) (InstallSpec, error) {
	aux := InstallSpec{}

	if err := json.Unmarshal(data, &aux); err != nil {
		return aux, err
	}
	// There have to be batteries
	if aux.TargetSummary.Batteries == nil {
		return aux, fmt.Errorf(ParseErrorMessage)
	}

	// There should be at least 3 batteries
	if len(aux.TargetSummary.Batteries) < 3 {
		return aux, fmt.Errorf(ParseErrorMessage)
	}

	// There have to be at least 1 postgres cluster
	if aux.TargetSummary.PostgresClusters == nil {
		return aux, fmt.Errorf(ParseErrorMessage)

	}
	if len(aux.TargetSummary.PostgresClusters) < 1 {
		return aux, fmt.Errorf(ParseErrorMessage)
	}

	return aux, nil
}

func (s *InstallSpec) MarshalJSON() ([]byte, error) {
	return json.Marshal(s)
}
