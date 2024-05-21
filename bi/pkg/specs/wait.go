package specs

import (
	"bi/pkg/kube"
	"context"
	"fmt"
	"log/slog"

	batchv1 "k8s.io/api/batch/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

func (spec *InstallSpec) WaitForBootstrap(ctx context.Context, kubeClient kube.KubeClient) error {
	inCluster, err := spec.GetBatteryConfigField("battery_core", "server_in_cluster")
	if err != nil {
		return fmt.Errorf("failed to determine if control server is running in cluster: %w", err)
	}

	// no need to wait for anything else if the control server isn't running in cluster
	if !inCluster.(bool) {
		return nil
	}

	maybeNamespace, err := spec.GetBatteryConfigField("battery_core", "core_namespace")
	if err != nil {
		return fmt.Errorf("failed to get core namespace: %w", err)
	}

	ns, ok := maybeNamespace.(string)
	if !ok {
		return fmt.Errorf("failed to get core namespace string. is type: %T", maybeNamespace)
	}

	for name, opts := range map[string]*kube.WatchOptions{
		"bootstrap job":   bootstrapJobWatchOpts(ns),
		"control server":  controlServerPodWatchOpts(ns),
		"host config map": batteryInfoConfigMapWatchOpts(ns),
	} {
		l := slog.With(slog.String("watch", name))
		l.Debug("Waiting for watch to complete...")
		if err := kubeClient.WatchFor(ctx, opts); err != nil {
			return fmt.Errorf("failed to wait for %s: %w", name, err)
		}
		l.Info("Finished waiting")
	}

	return nil
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
		Callback: func(u *unstructured.Unstructured) bool {
			var job batchv1.Job
			err := runtime.DefaultUnstructuredConverter.FromUnstructured(u.Object, &job)
			if err != nil {
				slog.Debug(
					"failed to convert unstructured object into typed resource",
					slog.String("namespace", u.GetNamespace()),
					slog.String("name", u.GetName()),
					slog.Any("err", err),
				)
				return true
			}

			// keep watching as long as there is no completion time
			return job.Status.CompletionTime == nil
		},
	}
}

func controlServerPodWatchOpts(ns string) *kube.WatchOptions {
	return &kube.WatchOptions{
		GVR:       schema.GroupVersionResource{Group: "", Version: "v1", Resource: "pods"},
		Namespace: ns,
		ListOpts: metav1.ListOptions{LabelSelector: metav1.FormatLabelSelector(&metav1.LabelSelector{
			MatchExpressions: []metav1.LabelSelectorRequirement{
				{
					Key:      "battery/app",
					Operator: metav1.LabelSelectorOpIn,
					Values:   []string{"battery-control-server"},
				},
			},
		})},
		Callback: func(u *unstructured.Unstructured) bool {
			var pod corev1.Pod
			err := runtime.DefaultUnstructuredConverter.FromUnstructured(u.Object, &pod)
			if err != nil {
				slog.Debug(
					"failed to convert unstructured object into typed resource",
					slog.String("namespace", u.GetNamespace()),
					slog.String("name", u.GetName()),
					slog.Any("err", err),
				)
				return true
			}

			// keep watching as long as the pod isn't running
			return pod.Status.Phase != corev1.PodRunning
		},
	}
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
					Values:   []string{"battery-control-server"},
				},
			},
		})},
		Callback: func(u *unstructured.Unstructured) bool {
			var cm corev1.ConfigMap
			err := runtime.DefaultUnstructuredConverter.FromUnstructured(u.Object, &cm)
			if err != nil {
				slog.Debug(
					"failed to convert unstructured object into typed resource",
					slog.String("namespace", u.GetNamespace()),
					slog.String("name", u.GetName()),
					slog.Any("err", err),
				)
				return true
			}

			// keep watching as long as hostname isn't set
			if cm.Data["hostname"] != "" {
				slog.Debug("got control server hostname", slog.String("hostname", cm.Data["hostname"]))
				return false
			}
			return true
		},
	}
}
