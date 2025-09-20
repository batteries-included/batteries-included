package specs

import (
	"net/http"
	"time"

	"bi/pkg/kube"
)

// GetHTTPClient returns an HTTP client configured for the given spec and kube client.
// It mirrors the previous getHTTPClient implementation but is exported so it can be
// reused across the package.
func GetHTTPClient(spec *InstallSpec, kubeClient kube.KubeClient) *http.Client {
	httpClient := &http.Client{
		Timeout: 10 * time.Second,
	}

	dialContext := kubeClient.GetDialContext()

	// Create HTTP client with WireGuard support if available and necessary
	if dialContext != nil && spec.KubeCluster.Provider == "kind" {
		httpClient.Transport = &http.Transport{
			DialContext: dialContext,
		}
	}

	return httpClient
}
