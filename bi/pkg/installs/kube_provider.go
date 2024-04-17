package installs

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"slices"

	"bi/pkg/cluster/kind"
	"bi/pkg/specs"
)

func (env *InstallEnv) StartKubeProvider(ctx context.Context) error {
	slog.Debug("starting provider")

	var err error

	provider := env.Spec.KubeCluster.Provider

	switch provider {
	case "kind":
		err = env.startLocal(ctx)
	case "aws":
		err = env.startAWS(ctx)
	case "provided":
	default:
		slog.Debug("unexpected provider", slog.String("provider", provider))
		err = fmt.Errorf("unknown provider")
	}

	if err != nil {
		return err
	}

	// Since we know that starting the provider was
	// successful, we can write the spec it sometimes
	// modifies the ips or other fields
	err = env.WriteSummary(true)
	if err != nil {
		return fmt.Errorf("error writing summary after provider start: %w", err)
	}

	if err := env.WriteKubeConfig(ctx, true); err != nil {
		return fmt.Errorf("error writing kubeconfig after provider start: %w", err)
	}

	if err := env.WriteWireGuardConfig(ctx, true); err != nil {
		return fmt.Errorf("error writing wireguard config after provider start: %w", err)
	}

	return nil
}

func (env *InstallEnv) StopKubeProvider(ctx context.Context) error {
	slog.Debug("stopping provider")

	return env.clusterProvider.Destroy(ctx)
}

func (env *InstallEnv) startLocal(ctx context.Context) error {
	err := env.clusterProvider.Create(ctx)
	if err != nil {
		return err
	}

	err = env.tryAddMetalIPs()
	if err != nil {
		return err
	}

	return nil
}

func (env *InstallEnv) startAWS(ctx context.Context) error {
	slog.Debug("Starting aws cluster")

	if err := env.clusterProvider.Create(ctx); err != nil {
		return err
	}

	buf := bytes.NewBuffer([]byte{})
	if err := env.clusterProvider.Outputs(ctx, buf); err != nil {
		return err
	}

	parsed, err := parseEKSOutputs(buf.Bytes())
	if err != nil {
		return err
	}

	if err := env.configureCoreBattery(parsed); err != nil {
		return err
	}

	if err := env.configureLBControllerBattery(parsed); err != nil {
		return err
	}

	if err := env.configureKarpenterBattery(parsed); err != nil {
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

func ixFunc(typ string) func(specs.BatterySpec) bool {
	return func(bs specs.BatterySpec) bool {
		return bs.Type == typ
	}
}

// NOTE(jdt): this should hopefully be temporary until we generate cluster name before spinning up cluster
func (env *InstallEnv) configureCoreBattery(outputs *eksOutputs) error {
	ix := slices.IndexFunc(env.Spec.TargetSummary.Batteries, ixFunc("battery_core"))

	if ix < 0 {
		return fmt.Errorf("tried to configure core battery but it wasn't found in install spec")
	}

	env.Spec.TargetSummary.Batteries[ix].Config["cluster_name"] = outputs.Cluster["name"].Value
	return nil
}

func (env *InstallEnv) configureLBControllerBattery(outputs *eksOutputs) error {
	ix := slices.IndexFunc(env.Spec.TargetSummary.Batteries, ixFunc("aws_load_balancer_controller"))

	if ix < 0 {
		return fmt.Errorf("tried to configure aws_load_balancer_controller battery but it wasn't found in install spec")
	}

	env.Spec.TargetSummary.Batteries[ix].Config["service_role_arn"] = outputs.LBController["roleARN"].Value

	return nil
}

func (env *InstallEnv) configureKarpenterBattery(outputs *eksOutputs) error {
	ix := slices.IndexFunc(env.Spec.TargetSummary.Batteries, ixFunc("karpenter"))

	if ix < 0 {
		return fmt.Errorf("tried to configure karpenter battery but it wasn't found in install spec")
	}

	env.Spec.TargetSummary.Batteries[ix].Config["node_role_name"] = outputs.Cluster["nodeRoleName"].Value
	env.Spec.TargetSummary.Batteries[ix].Config["queue_name"] = outputs.Karpenter["queueName"].Value
	env.Spec.TargetSummary.Batteries[ix].Config["service_role_arn"] = outputs.Karpenter["roleARN"].Value

	return nil
}

func (env *InstallEnv) tryAddMetalIPs() error {
	net, err := kind.GetMetalLBIPs()
	if err == nil {
		newIpSpec := specs.IPAddressPoolSpec{Name: "kind", Subnet: net}
		slog.Debug("adding docker ips for metal lb: ", slog.Any("range", newIpSpec))
		pools := []specs.IPAddressPoolSpec{}
		for _, pool := range env.Spec.TargetSummary.IPAddressPools {
			if pool.Name != "kind" {
				pools = append(pools, pool)
			} else {
				slog.Debug("skipping existing kind pool", slog.Any("pool", pool))
			}
		}
		pools = append(pools, newIpSpec)
		env.Spec.TargetSummary.IPAddressPools = pools
	}
	return nil
}
