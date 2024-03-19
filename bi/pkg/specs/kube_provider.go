package specs

import (
	"log/slog"

	"bi/pkg/docker"
	"bi/pkg/local"
)

func (spec *InstallSpec) StartKubeProvider() error {
	var err error

	switch spec.KubeCluster.Provider {
	case "kind":
		err = spec.startLocal()
	case "aws":
		err = spec.startAws()
	}

	if err != nil {
		return err
	}
	return nil
}

func (spec *InstallSpec) StopKubeProvider() error {
	var err error

	switch spec.KubeCluster.Provider {
	case "kind":
		err = spec.stopLocal()
	case "aws":
	}

	if err != nil {
		return err
	}
	return nil
}

func (spec *InstallSpec) startLocal() error {
	slog.Debug("Trying to start kind cluster (unless already running)")
	_, err := local.StartDefaultKindCluster()
	if err != nil {
		return err
	}

	err = spec.tryAddMetalIPs()
	if err != nil {
		return err
	}
	slog.Debug("kind cluster started successfully", slog.Any("ips", spec.TargetSummary.IPAddressPools))

	return nil
}

func (spec *InstallSpec) tryAddMetalIPs() error {
	net, err := docker.GetMetalLBIPs()
	if err == nil {
		newIpSpec := IPAddressPoolSpec{Name: "kind", Subnet: net}
		slog.Debug("adding docker ips for metal lb: ", slog.Any("range", newIpSpec))
		spec.TargetSummary.IPAddressPools = append(spec.TargetSummary.IPAddressPools, newIpSpec)
	}
	return nil
}

func (spec *InstallSpec) stopLocal() error {
	slog.Debug("Stopping kind cluster")
	err := local.StopDefaultKindCluster()
	if err != nil {
		return err
	}
	return nil
}

func (spec *InstallSpec) startAws() error {
	slog.Debug("Starting aws cluster")
	// TODO: Hook this up with pulumi that Jason wrote
	return nil
}
