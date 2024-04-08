package util

import (
	"encoding/json"
	"fmt"
	"net"
	"slices"
	"strconv"

	"github.com/pulumi/pulumi/sdk/v3/go/auto"
)

// NOTE(jdt): this kind of stinks. There doesn't appear to be a convenient way
// to convert the outputs from previous stacks into usable inputs.
// We just get an empty interface - `interface{}` - that we have to type
// assert. Perhaps we should use JSON?

// ToStringSlice takes a pulumi string array / slice output and converts it into a []string
func ToStringSlice(in interface{}) []string {
	out := []string{}
	for _, x := range in.([]interface{}) {
		out = append(out, x.(string))
	}
	// try to maintain some order so that things don't flip flop?
	slices.Sort(out)
	return out
}

func ServiceAccount(namespace, name string) string {
	return fmt.Sprintf("system:serviceaccount:%s:%s", namespace, name)
}

type PulumiConfig struct {
	AWS          aws
	Cluster      cluster
	Gateway      gateway
	Karpenter    karpenter
	LBController lbController
	VPC          vpc
}

// aws general config
type aws struct {
	// DefaultTags is the set of tags that the pulumi / TF provider will add to
	// all created resources
	DefaultTags map[string]string
	// The region to launch the cluster into
	Region string
}

// EKS config
type cluster struct {
	// AmiType is the EKS AMI Type e.g. AL2_X86_64
	AmiType string
	// CapacityType determines the type of instance to use e.g. spot vs on-demand
	CapacityType string
	// InstanceType is the type of instance of the bootstrap node group e.g. t3a.medium
	InstanceType string
	// DesiredSize is the desired size of the bootstrap node group
	DesiredSize int
	// MaxSize is the max size of the bootstrap node group
	MaxSize int
	// MinSize is the max size of the bootstrap node group
	MinSize int
	// Name is the name of the cluster. Additionally, it is used as the base name for virtually all resources
	Name string
	// Version is the cluster version e.g. 1.29
	Version string
	// VolumeSize is the size of the root volume for the bootstrap node group instances
	VolumeSize int
	// VolumeType is the type of the root EBS volume for the bootstrap node group instances e.g. gp3
	VolumeType string
}

// wireguard gateway config
type gateway struct {
	// CIDRBlock is the cidr to use for the wireguard networks e.g. 100.64.250.0/24
	CIDRBlock *net.IPNet
	// GenerateSSHKey determines whether an SSH key is created and used
	GenerateSSHKey bool
	// InstanceType is the type of instance to use for the wireguard bastion
	InstanceType string
	// Port is the port that wireguard will listen on
	Port int
	// VolumeSize is the size of the root volume of the wireguard instance
	VolumeSize int
	// VolumeType is the type of the root EBS volume for the wireguard instance e.g. gp3
	VolumeType string
}

type karpenter struct{ Namespace string }

type lbController struct{ Namespace string }

// vpc specific config
type vpc struct {
	// CIDRBlock is the cidr to use for the VPC e.g. 100.64.0.0/16
	CIDRBlock *net.IPNet
}

// ParsePulumiConfig parses pulumi cfg into a single struct that can be passed
// around instead of repeatedly parsing and formatting config
func ParsePulumiConfig(cfg auto.ConfigMap) (*PulumiConfig, error) {
	tags, err := parseDefaultTags(cfg["aws:defaultTags"].Value)
	if err != nil {
		return nil, err
	}

	_, gwCIDR, err := net.ParseCIDR(cfg["gateway:cidrBlock"].Value)
	if err != nil {
		return nil, err
	}

	genKey, err := strconv.ParseBool(cfg["gateway:generateSSHKey"].Value)
	if err != nil {
		return nil, err
	}

	port, err := strconv.Atoi(cfg["gateway:port"].Value)
	if err != nil {
		return nil, err
	}

	volSize, err := strconv.Atoi(cfg["gateway:volumeSize"].Value)
	if err != nil {
		return nil, err
	}

	_, vpcCIDR, err := net.ParseCIDR(cfg["vpc:cidrBlock"].Value)
	if err != nil {
		return nil, err
	}

	desiredSize, err := strconv.Atoi(cfg["cluster:desiredSize"].Value)
	if err != nil {
		return nil, err
	}

	maxSize, err := strconv.Atoi(cfg["cluster:maxSize"].Value)
	if err != nil {
		return nil, err
	}

	minSize, err := strconv.Atoi(cfg["cluster:minSize"].Value)
	if err != nil {
		return nil, err
	}

	clusterVolSize, err := strconv.Atoi(cfg["cluster:volumeSize"].Value)
	if err != nil {
		return nil, err
	}

	pc := &PulumiConfig{
		AWS: aws{
			DefaultTags: tags,
			Region:      cfg["aws:region"].Value,
		},
		Cluster: cluster{
			AmiType:      cfg["cluster:amiType"].Value,
			CapacityType: cfg["cluster:capacityType"].Value,
			DesiredSize:  desiredSize,
			InstanceType: cfg["cluster:instanceType"].Value,
			MaxSize:      maxSize,
			MinSize:      minSize,
			Name:         cfg["cluster:name"].Value,
			Version:      cfg["cluster:version"].Value,
			VolumeSize:   clusterVolSize,
			VolumeType:   cfg["cluster:volumeType"].Value,
		},
		Gateway: gateway{
			CIDRBlock:      gwCIDR,
			GenerateSSHKey: genKey,
			InstanceType:   cfg["gateway:instanceType"].Value,
			Port:           port,
			VolumeSize:     volSize,
			VolumeType:     cfg["gateway:volumeType"].Value,
		},
		Karpenter:    karpenter{Namespace: cfg["karpenter:namespace"].Value},
		LBController: lbController{Namespace: cfg["lbcontroller:namespace"].Value},
		VPC:          vpc{CIDRBlock: vpcCIDR},
	}

	return pc, nil
}

func parseDefaultTags(s string) (map[string]string, error) {
	// don't use Tags as we want to keep the full tags and it doesn't make
	// sense to go unmarshal and then re-marshal?
	raw := map[string]interface{}{}
	if err := json.Unmarshal([]byte(s), &raw); err != nil {
		return nil, err
	}

	inner, ok := raw["tags"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("tags not in correct format")
	}

	tags := make(map[string]string)
	for k, v := range inner {
		tags[k] = v.(string)
	}

	return tags, nil
}
