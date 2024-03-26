package specs

import (
	"context"
	"fmt"
	"log/slog"
	"os"

	"bi/pkg/cluster"
	"bi/pkg/docker"
	"bi/pkg/local"

	"github.com/adrg/xdg"
)

func (spec *InstallSpec) StartKubeProvider() error {
	var err error

	switch spec.KubeCluster.Provider {
	case "kind":
		err = spec.startLocal()
	case "aws":
		err = spec.startAws()
	case "provided":
	default:
		slog.Debug("unexpected provider", slog.String("provider", spec.KubeCluster.Provider))
		err = fmt.Errorf("unknown provider")
	}

	return err
}

func (spec *InstallSpec) StopKubeProvider() error {
	var err error

	switch spec.KubeCluster.Provider {
	case "kind":
		err = spec.stopLocal()
	case "aws":
	case "provided":
	}

	return err
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
	ctx := context.Background()

	p := cluster.NewPulumiProvider()
	if err := p.Init(ctx); err != nil {
		return err
	}

	if err := p.Create(ctx); err != nil {
		return err
	}

	out, err := xdg.RuntimeFile("bi/outputs.json")
	if err != nil {
		return err
	}

	f, err := os.OpenFile(out, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0o700)
	if err != nil {
		return err
	}
	defer f.Close()

	if err := p.Outputs(ctx, f); err != nil {
		return err
	}

	return nil
}
