package specs

func (spec *InstallSpec) NeedsLocalGateway() (bool, error) {
	usage, err := spec.GetBatteryConfigField("battery_core", "usage")
	if err != nil {
		return false, err
	}
	return spec.KubeCluster.Provider == "kind" && usage != "internal_dev", nil
}
