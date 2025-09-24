package installs

import (
	"bi/pkg/cluster/kind"
	"bi/pkg/kube"
	"bi/pkg/rage"
	"bi/pkg/specs"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"golang.org/x/exp/slog"
)

func (env *InstallEnv) NewRage(ctx context.Context) (*rage.RageReport, error) {
	report := &rage.RageReport{InstallSlug: env.Slug, KubeExists: false, PodsInfo: []rage.PodRageInfo{}, HttpRoutes: []rage.HttpRouteRageInfo{}}
	// Add the logs from the local command line invocations
	err := env.addBILogs(report)
	if err != nil {
		slog.Error("unable to add local bi logs", "error", err)
	}

	// Get any kube provider specific info
	if env.Spec.KubeCluster.Provider == "kind" {
		err := env.addKindRageInfo(ctx, report)
		if err != nil {
			slog.Error("unable to add kind info", "error", err)
		}
	}

	// Get info about all the pods
	kubeClient, err := env.NewBatteryKubeClient()
	if err != nil {
		slog.Error("unable to create kube client", "error", err)
		return nil, err
	}
	defer kubeClient.Close()
	err = env.addKubeRageInfo(ctx, kubeClient, report)
	if err != nil {
		slog.Error("unable to add kube info to the rage report", "error", err)
		return nil, err
	}

	// Add node information
	nodes, err := kubeClient.ListNodesRage(ctx)
	if err != nil {
		slog.Error("unable to list nodes for rage", "error", err)
	} else {
		report.Nodes = nodes
	}

	err = env.addHttpRoutes(ctx, kubeClient, report)
	if err != nil {
		slog.Error("unable to add HTTP routes to the rage report", "error", err)
	}

	// Create HTTP client with VPN support and collect metrics
	httpClient := specs.GetHTTPClient(env.Spec, kubeClient)
	err = env.addMetrics(ctx, httpClient, report)
	if err != nil {
		slog.Error("unable to add metrics data", "error", err)
		// Non-fatal error - continue with rage report generation
	}

	return report, nil
}

func (env *InstallEnv) addKindRageInfo(ctx context.Context, report *rage.RageReport) error {
	ips, err := kind.GetMetalLBIPs(ctx)
	if err != nil {
		slog.Warn("unable to get kind ips", "error", err)
		return err
	}

	report.KindIPs = &ips
	return nil
}

func (env *InstallEnv) addKubeRageInfo(ctx context.Context, kubeClient kube.KubeClient, report *rage.RageReport) error {
	ns, err := env.Spec.GetCoreNamespace()
	if err != nil {
		return fmt.Errorf("failed to get core namespace: %w", err)
	}

	if err := kubeClient.WaitForConnection(3 * time.Minute); err != nil {
		return fmt.Errorf("cluster did not become ready for rage: %w", err)
	}

	// Since we got here the cluster is somewhat ready
	report.KubeExists = true
	pods, err := kubeClient.ListPodsRage(ctx)
	if err != nil {
		slog.Error("unable to list pods", "error", err)
	} else {
		report.PodsInfo = pods
	}

	accessInfo, err := kubeClient.GetAccessInfo(ctx, ns)
	if err != nil {
		slog.Error("unable to get access info", "error", err)
	} else {
		report.AccessSpec = accessInfo
	}

	return nil
}

func (env *InstallEnv) addBILogs(report *rage.RageReport) error {
	logsPath := env.BaseLogPath()

	// List all the files in the logs directory
	files, err := os.ReadDir(logsPath)
	if err != nil {
		return fmt.Errorf("unable to read logs directory: %w", err)
	}
	results := make(map[string][]interface{})

	for _, file := range files {
		if file.IsDir() {
			continue
		}
		path := filepath.Join(logsPath, file.Name())
		f, err := os.Open(path)
		if err != nil {
			// handle error
			continue
		}
		defer f.Close()
		fileResults := make([]interface{}, 0)

		d := json.NewDecoder(f)
		for {
			var v interface{}
			if err := d.Decode(&v); err == io.EOF {
				break // done decoding file
			}
			fileResults = append(fileResults, v)
		}

		results[file.Name()] = fileResults
	}

	report.BILogs = results

	return nil
}

func (env *InstallEnv) addHttpRoutes(ctx context.Context, kubeClient kube.KubeClient, report *rage.RageReport) error {
	httpRoutes, err := kubeClient.ListHttpRoutesRage(ctx)
	if err != nil {
		slog.Error("unable to list HTTP routes", "error", err)
		return err
	}

	report.HttpRoutes = httpRoutes
	return nil
}

func (env *InstallEnv) addMetrics(ctx context.Context, httpClient *http.Client, report *rage.RageReport) error {
	if report.AccessSpec == nil {
		return fmt.Errorf("no access spec available to get control server info")
	}

	baseUrl := report.AccessSpec.GetURL()
	metricsURL := fmt.Sprintf("%s/api/metrics/json", baseUrl)
	slog.Debug("Fetching control server metrics", "url", metricsURL)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, metricsURL, nil)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	// Set a reasonable timeout on the context if not already set
	ctx, cancel := context.WithTimeout(req.Context(), 15*time.Second)
	defer cancel()
	req = req.WithContext(ctx)

	resp, err := httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to request control server metrics: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("control server metrics returned status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	// Decode the JSON response into a generic map
	var metricsData map[string]interface{}
	dec := json.NewDecoder(resp.Body)
	if err := dec.Decode(&metricsData); err != nil {
		return fmt.Errorf("failed to decode control server metrics JSON: %w", err)
	}

	report.Metrics = metricsData

	return nil
}
