package cmd

type SharedRegistryFlags struct {
	ignoredImages []string
	dryRun        bool
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

	// Major Redis version bump breaks things
	"quay.io/opstree/redis",
}
