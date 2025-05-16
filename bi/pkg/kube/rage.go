package kube

import (
	"bi/pkg/rage"
	"context"
	"log/slog"
	"strings"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func (client *batteryKubeClient) ListPodsRage(ctx context.Context) ([]rage.PodRageInfo, error) {
	// list all the namespaces
	namespaces, err := client.client.CoreV1().Namespaces().List(ctx, metav1.ListOptions{})
	if err != nil {
		return nil, err
	}
	results := make([]rage.PodRageInfo, 0)

	for _, namespace := range namespaces.Items {
		if !strings.Contains(namespace.Name, "battery") {
			continue
		}
		slog.Debug("Listing pods", "namespace", namespace.Name)
		pods, err := client.client.CoreV1().Pods(namespace.Name).List(ctx, metav1.ListOptions{})
		if err != nil {
			return nil, err
		}
		for _, pod := range pods.Items {
			slog.Debug("Getting pod rage info", "namespace", namespace.Name, "pod", pod.Name)
			podRageInfo, err := client.GetPodRageInfo(ctx, namespace.Name, pod.Name)
			if err != nil {
				slog.Warn("unable to get pod rage info", "namespace", namespace.Name, "pod", pod.Name, "error", err)
				continue
			}

			results = append(results, *podRageInfo)
		}
	}
	slog.Debug("Listed pods", "count", len(results))
	return results, nil
}

func (client *batteryKubeClient) GetPodRageInfo(ctx context.Context, namespace, podName string) (*rage.PodRageInfo, error) {
	pod, err := client.client.CoreV1().Pods(namespace).Get(ctx, podName, metav1.GetOptions{})
	if err != nil {
		return nil, err
	}
	containerInfos := make(map[string]rage.ContainerRageInfo)
	for _, container := range pod.Status.ContainerStatuses {
		running := container.State.Running != nil

		logs := ""
		if running {
			logs, err = client.GetLogs(ctx, namespace, podName, container.Name)

			if err != nil {
				slog.Warn("unable to get logs",
					slog.String("namespace", namespace),
					slog.String("pod", podName),
					slog.String("container", container.Name),
					slog.Any("error", err),
				)
			}
		}
		info := rage.ContainerRageInfo{
			Name:         container.Name,
			Running:      container.State.Running != nil,
			RestartCount: int(container.RestartCount),
			Logs:         string(logs),
		}
		containerInfos[container.Name] = info
	}
	return &rage.PodRageInfo{
		Namespace:     pod.Namespace,
		Name:          pod.Name,
		Phase:         string(pod.Status.Phase),
		Message:       pod.Status.Message,
		ContainerInfo: containerInfos,
	}, nil
}

func (client *batteryKubeClient) GetLogs(ctx context.Context, namespace, podName, containerName string) (string, error) {
	tailLines := int64(20)
	logs, err := client.client.CoreV1().Pods(namespace).GetLogs(podName, &v1.PodLogOptions{Container: containerName, TailLines: &tailLines}).Do(ctx).Raw()
	if err != nil {
		return "", err
	}
	return string(logs), nil
}
