package specs

import (
	"bi/pkg/cluster/util"
	"bi/pkg/kube"
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"github.com/avast/retry-go/v4"
	"github.com/vbauerster/mpb/v8"
	appsv1 "k8s.io/api/apps/v1"
	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

// testFn tests a converted object returned from a watch to determine if the watch is done or errored
type testFn[T any] func(convertedAPIObject *T) (done bool, err error)

func (spec *InstallSpec) WaitForBootstrap(ctx context.Context, kubeClient kube.KubeClient, progressReporter *util.ProgressReporter) error {
	usage, err := spec.GetCoreUsage()
	if err != nil {
		return fmt.Errorf("failed to determine if control server is running in cluster: %w", err)
	}

	// no need to wait for anything else if the control server isn't running in cluster
	if usage == "internal_dev" {
		slog.Debug("control server not running in cluster, skipping wait")
		return nil
	}

	var bootstrapBar *mpb.Bar
	if progressReporter != nil {
		bootstrapBar = progressReporter.ForBootstrapProgress()
	}

	ns, err := spec.GetCoreNamespace()
	if err != nil {
		return fmt.Errorf("failed to get core namespace: %w", err)
	}

	util.IncrementWithMessage(bootstrapBar, "Starting bootstrap wait")

	watchSteps := map[string]*kube.WatchOptions{
		"bootstrap job":   bootstrapJobWatchOpts(ns),
		"control server":  controlServerStatefulSetWatchOpts(ns),
		"host config map": batteryInfoConfigMapWatchOpts(ns),
	}

	stepCount := 0
	for name, opts := range watchSteps {
		l := slog.With(slog.String("watch", name))
		l.Debug("Waiting for watch to complete...")
		if err := kubeClient.WatchFor(ctx, opts); err != nil {
			return fmt.Errorf("failed to wait for %s: %w", name, err)
		}
		l.Info("Finished waiting")
		stepCount++
		util.IncrementWithMessage(bootstrapBar, fmt.Sprintf("Completed %s", name))
	}

	util.IncrementWithMessage(bootstrapBar, "Getting access info")

	httpClient := getHTTPClient(spec, kubeClient)

	// Create a separate progress bar for HTTP health check
	var healthBar *mpb.Bar
	if progressReporter != nil {
		healthBar = progressReporter.ForHealthCheck()
	}

	util.IncrementWithMessage(healthBar, "Starting control server health check")

	// try to get cs url and connect, 10x
	attemptCount := 0
	err = retry.Do(func() error {
		attemptCount++
		// get the access-info configmap (and URL information)
		info, err := kubeClient.GetAccessInfo(ctx, ns)
		if err != nil {
			slog.Debug("Failed to get access info config map", slog.Any("error", err))
			util.IncrementWithMessage(healthBar, fmt.Sprintf("Attempt %d: Failed to get access info", attemptCount))
			return err
		}

		baseUrl := info.GetURL()
		// Try the health endpoint after the base URL
		healthCheckUrl := fmt.Sprintf("%s/healthz", baseUrl)

		// try to make sure the control server is up before we return
		slog.Debug("Attempting to connect to control server", slog.String("baseUrl", baseUrl), slog.String("url", healthCheckUrl))
		_, err = httpClient.Head(baseUrl)
		if err != nil {
			util.IncrementWithMessage(healthBar, fmt.Sprintf("Attempt %d: Health check failed", attemptCount))
		} else {
			util.IncrementWithMessage(healthBar, fmt.Sprintf("Attempt %d: Health check successful", attemptCount))
		}

		util.IncrementWithMessage(healthBar, "Re-checking health...")

		// try again to make sure we are stable
		_, err = httpClient.Head(healthCheckUrl)
		if err != nil {
			util.IncrementWithMessage(healthBar, fmt.Sprintf("Attempt %d: Second health check failed", attemptCount))
		} else {
			util.IncrementWithMessage(healthBar, fmt.Sprintf("Attempt %d: Second health check successful", attemptCount))
		}

		return err
	}, retry.Context(ctx))

	if err == nil {
		util.SetTotalAndComplete(healthBar)
		util.IncrementWithMessage(bootstrapBar, "Control server accessible")
		util.IncrementWithMessage(bootstrapBar, "Bootstrap complete")
		util.SetTotalAndComplete(bootstrapBar)
	} else {
		util.SetTotalAndComplete(healthBar)
	}

	return err
}

func getHTTPClient(spec *InstallSpec, kubeClient kube.KubeClient) *http.Client {
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

func bootstrapJobWatchOpts(ns string) *kube.WatchOptions {
	return &kube.WatchOptions{
		GVR:       schema.GroupVersionResource{Group: "batch", Version: "v1", Resource: "jobs"},
		Namespace: ns,
		ListOpts: metav1.ListOptions{LabelSelector: metav1.FormatLabelSelector(&metav1.LabelSelector{
			MatchExpressions: []metav1.LabelSelectorRequirement{
				{
					Key:      "battery/app",
					Operator: metav1.LabelSelectorOpIn,
					Values:   []string{"battery-core"},
				},
			},
		})},
		Callback: buildCallback(func(job *batchv1.Job) (bool, error) {
			var err error = nil
			if jobFailed(job.Status.Conditions) {
				err = fmt.Errorf("bootstrap job failed")
			}

			// keep watching as long as there is no completion time
			return job.Status.CompletionTime != nil, err
		}),
	}
}

func jobFailed(conditions []batchv1.JobCondition) bool {
	for _, c := range conditions {
		if c.Type == batchv1.JobFailed && c.Status == corev1.ConditionTrue {
			return true
		}
	}
	return false
}

func controlServerStatefulSetWatchOpts(ns string) *kube.WatchOptions {
	return &kube.WatchOptions{
		GVR:       schema.GroupVersionResource{Group: "apps", Version: "v1", Resource: "statefulsets"},
		Namespace: ns,
		ListOpts:  controlServerListOpts(),
		Callback:  buildCallback(deployReady),
	}
}

func controlServerListOpts() metav1.ListOptions {
	return metav1.ListOptions{LabelSelector: metav1.FormatLabelSelector(&metav1.LabelSelector{
		MatchExpressions: []metav1.LabelSelectorRequirement{
			{
				Key:      "battery/app",
				Operator: metav1.LabelSelectorOpIn,
				Values:   []string{"battery-control-server"},
			},
		},
	})}
}

func deployReady(deploy *appsv1.Deployment) (bool, error) {
	status := deploy.Status

	return status.ObservedGeneration > 1 &&
			status.AvailableReplicas > 0 &&
			status.UpdatedReplicas > 0 &&
			status.ReadyReplicas > 0,
		nil
}

func batteryInfoConfigMapWatchOpts(ns string) *kube.WatchOptions {
	return &kube.WatchOptions{
		GVR:       schema.GroupVersionResource{Group: "", Version: "v1", Resource: "configmaps"},
		Namespace: ns,
		ListOpts: metav1.ListOptions{LabelSelector: metav1.FormatLabelSelector(&metav1.LabelSelector{
			MatchExpressions: []metav1.LabelSelectorRequirement{
				{
					Key:      "battery/app",
					Operator: metav1.LabelSelectorOpIn,
					Values:   []string{"battery-access-info"},
				},
			},
		})},
		Callback: buildCallback(func(cm *corev1.ConfigMap) (bool, error) {
			// keep watching as long as hostname isn't set
			if cm.Data["hostname"] != "" {
				slog.Debug("got control server hostname", slog.String("hostname", cm.Data["hostname"]))
				return true, nil
			}
			return false, nil
		}),
	}
}

func buildCallback[T any](fn testFn[T]) func(u *unstructured.Unstructured) (bool, error) {
	return func(u *unstructured.Unstructured) (bool, error) {
		var obj *T
		err := runtime.DefaultUnstructuredConverter.FromUnstructured(u.Object, &obj)
		if err != nil {
			slog.Debug(
				"failed to convert unstructured object into typed resource",
				slog.String("namespace", u.GetNamespace()),
				slog.String("name", u.GetName()),
				slog.Any("error", err),
			)
			return false, nil
		}
		return fn(obj)
	}
}
