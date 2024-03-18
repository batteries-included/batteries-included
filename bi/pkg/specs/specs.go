package specs

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
	Batteries        []BatterySpec            `json:"batteries"`
	IPAddressPools   []IPAddressPoolSpec      `json:"ip_address_pools"`
	KnativeServices  []map[string]interface{} `json:"knative_services"`
	Notebooks        []map[string]interface{} `json:"notebooks"`
	PostgresClusters []map[string]interface{} `json:"postgres_clusters"`
	FerretServices   []map[string]interface{} `json:"ferret_services"`
	RedisClusters    []map[string]interface{} `json:"redis_clusters"`
}

type InstallSpec struct {
	InitialResources map[string]map[string]interface{} `json:"initial_resources"`
	KubeCluster      KubeClusterSpec                   `json:"kube_cluster"`
	TargetSummary    StateSummarySpec                  `json:"target_summary"`
}
