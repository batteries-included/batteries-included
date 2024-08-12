package specs

type KubeClusterSpec struct {
	Provider string         `json:"provider"`
	Config   map[string]any `json:"config"`
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
	Batteries           []BatterySpec            `json:"batteries"`
	IPAddressPools      []IPAddressPoolSpec      `json:"ip_address_pools"`
	FerretServices      []map[string]interface{} `json:"ferret_services"`
	KnativeServices     []map[string]interface{} `json:"knative_services"`
	Notebooks           []map[string]interface{} `json:"notebooks"`
	PostgresClusters    []map[string]interface{} `json:"postgres_clusters"`
	RedisInstances      []map[string]interface{} `json:"redis_instances"`
	TraditionalServices []map[string]interface{} `json:"traditional_services"`
}

type InstallSpec struct {
	Slug             string                            `json:"slug"`
	InitialResources map[string]map[string]interface{} `json:"initial_resources"`
	KubeCluster      KubeClusterSpec                   `json:"kube_cluster"`
	TargetSummary    StateSummarySpec                  `json:"target_summary"`
}
