package specs

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/netip"
	"os"
	"slices"

	"bi/cmd/cmdutil"
	"bi/pkg/cluster"
	"bi/pkg/docker"
	"bi/pkg/local"
	"bi/pkg/wireguard"
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

	if err := spec.configureCoreBattery(parsed); err != nil {
		return err
	}

	if err := spec.configureLBControllerBattery(parsed); err != nil {
		return err
	}

	if err := spec.configureKarpenterBattery(parsed); err != nil {
		return err
	}

	if err := saveWireGuardClientConfig(parsed); err != nil {
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

// NOTE(jdt): this should hopefully be temporary until we generate cluster name before spinning up cluster
func (spec *InstallSpec) configureCoreBattery(outputs *eksOutputs) error {
	ix := slices.IndexFunc(spec.TargetSummary.Batteries, ixFunc("battery_core"))

	if ix < 0 {
		return fmt.Errorf("tried to configure core battery but it wasn't found in install spec")
	}

	spec.TargetSummary.Batteries[ix].Config["cluster_name"] = outputs.Cluster["name"].Value
	return nil
}

func (spec *InstallSpec) configureLBControllerBattery(outputs *eksOutputs) error {
	ix := slices.IndexFunc(spec.TargetSummary.Batteries, ixFunc("aws_load_balancer_controller"))

	if ix < 0 {
		return fmt.Errorf("tried to configure aws_load_balancer_controller battery but it wasn't found in install spec")
	}

	spec.TargetSummary.Batteries[ix].Config["service_role_arn"] = outputs.LBController["roleARN"].Value

	return nil
}

func (spec *InstallSpec) configureKarpenterBattery(outputs *eksOutputs) error {
	ix := slices.IndexFunc(spec.TargetSummary.Batteries, ixFunc("karpenter"))

	if ix < 0 {
		return fmt.Errorf("tried to configure karpenter battery but it wasn't found in install spec")
	}

	spec.TargetSummary.Batteries[ix].Config["node_role_name"] = outputs.Cluster["nodeRoleName"].Value
	spec.TargetSummary.Batteries[ix].Config["queue_name"] = outputs.Karpenter["queueName"].Value
	spec.TargetSummary.Batteries[ix].Config["service_role_arn"] = outputs.Karpenter["roleARN"].Value

	return nil
}

func ixFunc(typ string) func(BatterySpec) bool {
	return func(bs BatterySpec) bool {
		return bs.Type == typ
	}
}

func saveWireGuardClientConfig(outputs *eksOutputs) error {
	gwEndpoint := netip.AddrPortFrom(netip.MustParseAddr(outputs.Gateway["publicIP"].Value.(string)),
		uint16(outputs.Gateway["publicPort"].Value.(float64)))

	gw := wireguard.Gateway{
		PrivateKey: outputs.Gateway["wgGatewayPrivateKey"].Value.(string),
		Address:    netip.MustParseAddr(outputs.Gateway["wgGatewayAddress"].Value.(string)),
		Endpoint:   gwEndpoint,
	}

	installerClient := wireguard.Client{
		Gateway:    &gw,
		Name:       "installer",
		PrivateKey: outputs.Gateway["wgClientPrivateKey"].Value.(string),
		Address:    netip.MustParseAddr(outputs.Gateway["wgClientAddress"].Value.(string)),
	}

	// Write the wireguard config for the installer client.
	wireGuardConfigPath, err := cmdutil.DefaultWireGuardConfigPath()
	if err != nil {
		return fmt.Errorf("error getting wireguard config path: %w", err)
	}

	wireGuardConfigFile, err := os.OpenFile(wireGuardConfigPath, os.O_CREATE|os.O_WRONLY, 0o400)
	if err != nil {
		return fmt.Errorf("error opening wireguard config file: %w", err)
	}
	defer wireGuardConfigFile.Close()

	if err := installerClient.WriteConfig(wireGuardConfigFile); err != nil {
		return fmt.Errorf("error writing wireguard config: %w", err)
	}

	return nil
}
