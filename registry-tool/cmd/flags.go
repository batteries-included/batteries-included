package cmd

import "time"

type SharedRegistryFlags struct {
	ignoredImages []string
	dryRun        bool
	delay         time.Duration
	jitter        time.Duration
	maxFailures   int
}

var DefaultIgnoredImages = []string{
	// This isn't a real image
	"ecto/schema/test",
	// AWS things aren't integration tested yet
	"public.ecr.aws/karpenter/controller",
	// AWS isn't integration tested yet
	"public.ecr.aws/eks/aws-load-balancer-controller",
	// Grafana JS is broken
	//
	// https://github.com/grafana/grafana/issues/105582
	//
	// Error:
	// ```
	//  Uncaught TypeError: Cannot read properties of undefined (reading 'keys')
	// ```
	"docker.io/grafana/grafana",

	// No Users are not ready for Cuda versions to be automatically updated
	"docker.io/nvidia/cuda",

	// temporarily disable advancing ferret default to allow upgrade
	"ghcr.io/ferretdb/ferretdb",
}
