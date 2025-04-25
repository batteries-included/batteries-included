package specs

import (
	"bi/pkg/kube"
	"context"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/avast/retry-go/v4"
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

func (spec *InstallSpec) WaitForBootstrap(ctx context.Context, kubeClient kube.KubeClient) error {
	usage, err := spec.GetBatteryConfigField("battery_core", "usage")
	if err != nil {
		return fmt.Errorf("failed to determine if control server is running in cluster: %w", err)
	}

	// no need to wait for anything else if the control server isn't running in cluster
	if usage.(string) == "internal_dev" {
		slog.Debug("control server not running in cluster, skipping wait")
		return nil
	}

	ns, err := spec.GetCoreNamespace()
	if err != nil {
		return fmt.Errorf("failed to get core namespace: %w", err)
	}

	for name, opts := range map[string]*kube.WatchOptions{
		"bootstrap job":   bootstrapJobWatchOpts(ns),
		"control server":  controlServerDeployWatchOpts(ns),
		"host config map": batteryInfoConfigMapWatchOpts(ns),
	} {
		l := slog.With(slog.String("watch", name))
		l.Debug("Waiting for watch to complete...")
		if err := kubeClient.WatchFor(ctx, opts); err != nil {
			return fmt.Errorf("failed to wait for %s: %w", name, err)
		}
		l.Info("Finished waiting")
	}

	// try to get cs url and connect, 10x
	err = retry.Do(func() error {
		// get the access-info configmap (and URL information)
		info, err := kubeClient.GetAccessInfo(ctx, ns)
		if err != nil {
			slog.Debug("Failed to get access info config map", slog.Any("error", err))
			return err
		}
		url := info.GetURL()

		// try to make sure the control server is up before we return
		slog.Debug("Attempting to connect to control server", slog.String("url", url))
		_, err = http.Head(url)
		return err
	}, retry.Context(ctx))

	return err
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

func controlServerDeployWatchOpts(ns string) *kube.WatchOptions {
	return &kube.WatchOptions{
		GVR:       schema.GroupVersionResource{Group: "apps", Version: "v1", Resource: "deployments"},
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
