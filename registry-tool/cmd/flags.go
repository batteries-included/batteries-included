package cmd

type SharedRegistryFlags struct {
	ignoredImages []string
	dryRun        bool
}

var DefaultIgnoredImages = []string{
	// This isn't a real image
	"ecto/schema/test",
	// Metallb images fail to bootstrap with our config
	"quay.io/metallb/speaker", "quay.io/metallb/controller", "quay.io/frrouting/frr",
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
	// Victoria Metricss needs new CRDS and a refresh
	"docker.io/victoriametrics/operator",
}
