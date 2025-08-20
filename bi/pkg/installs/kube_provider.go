package installs

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"

	"bi/pkg/cluster/kind"
	"bi/pkg/cluster/util"
	"bi/pkg/specs"
)

func (env *InstallEnv) StartKubeProvider(ctx context.Context, progressReporter *util.ProgressReporter) error {
	slog.Debug("Starting provider")

	var err error

	provider := env.Spec.KubeCluster.Provider

	switch provider {
	case "kind":
		err = env.startLocal(ctx, progressReporter)
	case "aws":
		err = env.startAWS(ctx, progressReporter)
	case "provided":
	default:
		err = fmt.Errorf("unknown provider: %s", provider)
	}
	if err != nil {
		return err
	}

	// Since we know that starting the provider was
	// successful, we can write the spec it sometimes
	// modifies the ips or other fields
	if err := env.WriteSummary(true); err != nil {
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

func (env *InstallEnv) StopKubeProvider(ctx context.Context, progressReporter *util.ProgressReporter) error {
	slog.Debug("Stopping provider")

	return env.clusterProvider.Destroy(ctx, progressReporter)
}

func (env *InstallEnv) startLocal(ctx context.Context, progressReporter *util.ProgressReporter) error {
	slog.Debug("Starting local cluster")

	if err := env.clusterProvider.Create(ctx, progressReporter); err != nil {
		return fmt.Errorf("error creating local cluster: %w", err)
	}

	if err := env.addMetalIPs(ctx); err != nil {
		return fmt.Errorf("error adding metal ips: %w", err)
	}

	if env.ClusterProvider().HasNvidiaRuntimeInstalled() {
		if err := env.addNvidiaLocalSpecResource(ctx); err != nil {
			return fmt.Errorf("error adding NVIDIA initial resources: %w", err)
		}
	}

	return nil
}

func (env *InstallEnv) startAWS(ctx context.Context, progressReporter *util.ProgressReporter) error {
	slog.Debug("Starting aws cluster")

	if err := env.clusterProvider.Create(ctx, progressReporter); err != nil {
		return fmt.Errorf("error creating aws cluster: %w", err)
	}

	var buf bytes.Buffer
	if err := env.clusterProvider.WriteOutputs(ctx, &buf); err != nil {
		return fmt.Errorf("error getting cluster outputs: %w", err)
	}

	parsed, err := parseEKSOutputs(buf.Bytes())
	if err != nil {
		return fmt.Errorf("error parsing cluster outputs: %w", err)
	}

	if err := env.configureLBControllerBattery(parsed); err != nil {
		return fmt.Errorf("error configuring lb controller battery: %w", err)
	}

	if err := env.configureKarpenterBattery(parsed); err != nil {
		return fmt.Errorf("error configuring karpenter battery: %w", err)
	}

	if err := env.configureCNPGBattery(parsed); err != nil {
		return fmt.Errorf("error configuring cloudnative_pg battery: %w", err)
	}

	if err := env.configureCNPGBarmanBattery(parsed); err != nil {
		return fmt.Errorf("error configuring cloudnative_pg_barman battery: %w", err)
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
	Postgres     map[string]output `json:"postgres"`
	VPC          map[string]output `json:"vpc"`
}

func parseEKSOutputs(output []byte) (*eksOutputs, error) {
	o := &eksOutputs{}
	err := json.Unmarshal(output, o)
	return o, err
}

func (env *InstallEnv) configureLBControllerBattery(outputs *eksOutputs) error {
	b, err := env.Spec.GetBatteryByType("aws_load_balancer_controller")
	if err != nil {
		return fmt.Errorf("aws_load_balancer_controller battery wasn't found in install spec")
	}

	b.Config["service_role_arn"] = outputs.LBController["roleARN"].Value

	eips, err := toStringSlice(outputs.LBController["eipAllocations"].Value.([]interface{}))
	if err != nil {
		return err
	}
	b.Config["eip_allocations"] = eips

	subnets, err := toStringSlice(outputs.VPC["publicSubnetIDs"].Value.([]interface{}))
	if err != nil {
		return err
	}
	b.Config["subnets"] = subnets

	return nil
}

func toStringSlice(maybeStrings []interface{}) ([]string, error) {
	ss := []string{}
	for _, in := range maybeStrings {
		s, ok := in.(string)
		if !ok {
			return nil, fmt.Errorf("failed parsing output into string")
		}
		ss = append(ss, s)
	}
	return ss, nil
}

func (env *InstallEnv) configureKarpenterBattery(outputs *eksOutputs) error {
	b, err := env.Spec.GetBatteryByType("karpenter")
	if err != nil {
		return fmt.Errorf("karpenter battery wasn't found in install spec")
	}

	b.Config["node_role_name"] = outputs.Cluster["nodeRoleName"].Value
	b.Config["queue_name"] = outputs.Karpenter["queueName"].Value
	b.Config["service_role_arn"] = outputs.Karpenter["roleARN"].Value

	return nil
}

func (env *InstallEnv) configureCNPGBattery(outputs *eksOutputs) error {
	b, err := env.Spec.GetBatteryByType("cloudnative_pg")
	if err != nil {
		return fmt.Errorf("cloudnative_pg battery wasn't found in install spec")
	}

	b.Config["bucket_name"] = outputs.Postgres["bucketName"].Value
	b.Config["bucket_arn"] = outputs.Postgres["bucketARN"].Value
	b.Config["service_role_arn"] = outputs.Postgres["roleARN"].Value

	return nil
}

// we're migrating to the barman plugin.
// it may not be part of the bootstrap so don't error
func (env *InstallEnv) configureCNPGBarmanBattery(outputs *eksOutputs) error {
	b, err := env.Spec.GetBatteryByType("cloudnative_pg_barman")
	if err != nil {
		slog.Debug("cloudnative_pg_barman battery wasn't found in install spec")
		return nil
	}

	b.Config["bucket_name"] = outputs.Postgres["bucketName"].Value
	b.Config["service_role_arn"] = outputs.Postgres["roleARN"].Value

	return nil
}

func (env *InstallEnv) addMetalIPs(ctx context.Context) error {
	net, err := kind.GetMetalLBIPs(ctx)
	if err != nil {
		return fmt.Errorf("error getting metal lb ips: %w", err)
	}

	newIpSpec := specs.IPAddressPoolSpec{Name: "kind", Subnet: net}

	slog.Debug("Adding docker ips for metal lb: ", slog.Any("range", newIpSpec))

	pools := []specs.IPAddressPoolSpec{}
	for _, pool := range env.Spec.TargetSummary.IPAddressPools {
		if pool.Name == "kind" {
			slog.Debug("Skipping existing kind pool", slog.Any("pool", pool))
			continue
		}
		pools = append(pools, pool)
	}
	pools = append(pools, newIpSpec)
	env.Spec.TargetSummary.IPAddressPools = pools

	return nil
}

func (env *InstallEnv) addNvidiaLocalSpecResource(_ context.Context) error {
	slog.Info("Adding NVIDIA runtime class to initial resources")

	runtimeClass := map[string]interface{}{
		"apiVersion": "node.k8s.io/v1",
		"kind":       "RuntimeClass",
		"metadata": map[string]interface{}{
			"name": "nvidia",
		},
		"handler": "nvidia",
	}

	env.Spec.InitialResources["gpu-runtime/runtime-class/nvidia"] = runtimeClass
	slog.Debug("NVIDIA runtime class added to initial resources")

	if !env.Spec.HasBatteryType("node_feature_discovery") {
		slog.Debug("Node feature discovery battery wasn't found in install spec")

		// Add the battery
		env.Spec.AddBattery(specs.BatterySpec{
			Type:  "node_feature_discovery",
			Group: "magic",
			Config: map[string]interface{}{
				"type": "node_feature_discovery",
			},
		})
	}

	if !env.Spec.HasBatteryType("nvidia_device_plugin") {
		slog.Debug("NVIDIA device plugin battery wasn't found in install spec")

		// Add the battery
		env.Spec.AddBattery(specs.BatterySpec{
			Type:  "nvidia_device_plugin",
			Group: "ai",
			Config: map[string]interface{}{
				"type": "nvidia_device_plugin",
			},
		})
	}

	return nil
}
