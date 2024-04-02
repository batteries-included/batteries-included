package specs

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"slices"

	"bi/pkg/cluster"
	"bi/pkg/docker"
	"bi/pkg/local"
)

func (spec *InstallSpec) StartKubeProvider() error {
	var err error

	switch spec.KubeCluster.Provider {
	case "kind":
		err = spec.startLocal()
	case "aws":
		err = spec.startAWS()
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

func (spec *InstallSpec) startAWS() error {
	slog.Debug("Starting aws cluster")
	ctx := context.Background()

	p := cluster.NewPulumiProvider()
	if err := p.Init(ctx); err != nil {
		return err
	}

	if err := p.Create(ctx); err != nil {
		return err
	}

	buf := bytes.NewBuffer([]byte{})
	if err := p.Outputs(ctx, buf); err != nil {
		return err
	}

	parsed, err := parseEKSOutputs(buf.Bytes())
	if err != nil {
		return err
	}
	if err := spec.configureKarpenterBattery(parsed); err != nil {
		return err
	}

	return nil
}

type output struct {
	Value  interface{}
	Secret bool
}

type eksOutputs struct {
	Cluster      map[string]output `json:"cluster"`
	Gateway      map[string]output `json:"gateway"`
	Karpenter    map[string]output `json:"karpenter"`
	LBController map[string]output `json:"lbcontroller"`
	VPC          map[string]output `json:"vpc"`
}

func parseEKSOutputs(output []byte) (*eksOutputs, error) {
	o := &eksOutputs{}
	err := json.Unmarshal(output, o)
	return o, err
}

func (spec *InstallSpec) configureKarpenterBattery(outputs *eksOutputs) error {
	ix := slices.IndexFunc(spec.TargetSummary.Batteries, func(bs BatterySpec) bool { return bs.Type == "karpenter" })

	if ix < 0 {
		return fmt.Errorf("tried to configure karpenter battery but it wasn't found in install spec")
	}

	spec.TargetSummary.Batteries[ix].Config["cluster_name"] = outputs.Cluster["name"].Value
	spec.TargetSummary.Batteries[ix].Config["node_role_name"] = outputs.Cluster["nodeRoleName"].Value
	spec.TargetSummary.Batteries[ix].Config["queue_name"] = outputs.Karpenter["queueName"].Value
	spec.TargetSummary.Batteries[ix].Config["service_role_arn"] = outputs.Karpenter["roleARN"].Value

	return nil
}
