package installs

import (
	"bi/pkg/cluster/kind"
	"bi/pkg/kube"
	"bi/pkg/rage"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"golang.org/x/exp/slog"
)

func (env *InstallEnv) NewRage(ctx context.Context) (*rage.RageReport, error) {
	report := &rage.RageReport{InstallSlug: env.Slug, KubeExists: false, PodsInfo: []rage.PodRageInfo{}}
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
