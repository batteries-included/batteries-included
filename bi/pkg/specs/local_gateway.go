package specs

import "strings"

func (spec *InstallSpec) NeedsLocalGateway() (bool, error) {
	usage, err := spec.GetCoreUsage()
	if err != nil {
		return false, err
	}
	return spec.KubeCluster.Provider == "kind" && !strings.HasPrefix(usage, "internal"), nil
}
