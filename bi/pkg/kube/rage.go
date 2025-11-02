package kube

import (
	"bi/pkg/rage"
	"context"
	"fmt"
	"log/slog"
	"strings"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

func (client *batteryKubeClient) ListPodsRage(ctx context.Context) ([]rage.PodRageInfo, error) {
	// list all the namespaces
	namespaces, err := client.client.CoreV1().Namespaces().List(ctx, metav1.ListOptions{})
	if err != nil {
		return nil, err
	}
	results := make([]rage.PodRageInfo, 0)

	for _, namespace := range namespaces.Items {
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

	// Get events for this pod
	events, err := client.GetPodEvents(ctx, namespace, podName)
	if err != nil {
		slog.Warn("unable to get events for pod",
			slog.String("namespace", namespace),
			slog.String("pod", podName),
			slog.Any("error", err),
		)
		// Continue without events rather than failing the whole pod info
		events = []rage.PodEventRageInfo{}
	}

	return &rage.PodRageInfo{
		Namespace:     pod.Namespace,
		Name:          pod.Name,
		Phase:         string(pod.Status.Phase),
		Message:       pod.Status.Message,
		ContainerInfo: containerInfos,
		Events:        events,
	}, nil
}

func (client *batteryKubeClient) GetLogs(ctx context.Context, namespace, podName, containerName string) (string, error) {
	tailLines := int64(128)
	logs, err := client.client.CoreV1().Pods(namespace).GetLogs(podName, &v1.PodLogOptions{Container: containerName, TailLines: &tailLines}).Do(ctx).Raw()
	if err != nil {
		return "", err
	}
	return string(logs), nil
}

func (client *batteryKubeClient) GetPodEvents(ctx context.Context, namespace, podName string) ([]rage.PodEventRageInfo, error) {
	// Create field selector for events related to this specific pod
	fieldSelector := fmt.Sprintf("involvedObject.name=%s,involvedObject.kind=Pod", podName)

	// Get events for the pod
	events, err := client.client.CoreV1().Events(namespace).List(ctx, metav1.ListOptions{
		FieldSelector: fieldSelector,
	})
	if err != nil {
		return nil, fmt.Errorf("unable to get events for pod %s/%s: %w", namespace, podName, err)
	}

	eventInfos := make([]rage.PodEventRageInfo, 0, len(events.Items))
	for _, event := range events.Items {
		eventInfo := rage.PodEventRageInfo{
			Type:               event.Type,
			Reason:             event.Reason,
			Message:            event.Message,
			ReportingComponent: event.ReportingController,
		}

		// Handle timestamp formatting - Kubernetes events can have different timestamp formats
		if !event.FirstTimestamp.IsZero() {
			eventInfo.FirstTimestamp = event.FirstTimestamp.Format("2006-01-02T15:04:05Z")
		}
		if !event.LastTimestamp.IsZero() {
			eventInfo.LastTimestamp = event.LastTimestamp.Format("2006-01-02T15:04:05Z")
		}

		eventInfos = append(eventInfos, eventInfo)
	}

	return eventInfos, nil
}

func (client *batteryKubeClient) ListServicesRage(ctx context.Context) ([]rage.ServiceRageInfo, error) {
	slog.Debug("Getting service rage info")
	svcList, err := client.client.CoreV1().Services("").List(ctx, metav1.ListOptions{LabelSelector: "app.kubernetes.io/managed-by=batteries-included"})
	if err != nil {
		return nil, err
	}

	results := make([]rage.ServiceRageInfo, 0)
	for _, svc := range svcList.Items {
		ingresses := []string{}
		for _, v := range svc.Status.LoadBalancer.Ingress {
			if v.IP != "" {
				ingresses = append(ingresses, v.IP)
			}

			if v.Hostname != "" {
				ingresses = append(ingresses, v.Hostname)
			}
		}

		info := rage.ServiceRageInfo{
			Namespace:  svc.GetNamespace(),
			Name:       svc.GetName(),
			Type:       string(svc.Spec.Type),
			ClusterIPs: svc.Spec.ClusterIPs,
			Conditions: svc.Status.Conditions,
			Ingresses:  ingresses,
		}
		results = append(results, info)

	}

	return results, nil
}

func (client *batteryKubeClient) ListHttpRoutesRage(ctx context.Context) ([]rage.HttpRouteRageInfo, error) {
	// Define the GVR for HTTPRoute
	gvr := schema.GroupVersionResource{
		Group:    "gateway.networking.k8s.io",
		Version:  "v1",
		Resource: "httproutes",
	}

	// List all namespaces
	namespaces, err := client.client.CoreV1().Namespaces().List(ctx, metav1.ListOptions{})
	if err != nil {
		return nil, err
	}

	results := make([]rage.HttpRouteRageInfo, 0)

	for _, namespace := range namespaces.Items {
		// Focus on battery-related namespaces
		if !strings.Contains(namespace.Name, "battery") {
			continue
		}

		slog.Debug("Listing HTTPRoutes", "namespace", namespace.Name)

		// List HTTPRoutes in the namespace
		routes, err := client.dynamicClient.Resource(gvr).Namespace(namespace.Name).List(ctx, metav1.ListOptions{})
		if err != nil {
			slog.Warn("unable to list HTTPRoutes", "namespace", namespace.Name, "error", err)
			continue
		}

		for _, route := range routes.Items {
			routeInfo := client.extractHttpRouteInfo(&route)
			results = append(results, routeInfo)
		}
	}

	slog.Debug("Listed HTTPRoutes", "count", len(results))
	return results, nil
}

func (client *batteryKubeClient) ListNodesRage(ctx context.Context) ([]rage.NodeRageInfo, error) {
	nodes, err := client.client.CoreV1().Nodes().List(ctx, metav1.ListOptions{})
	if err != nil {
		return nil, err
	}

	results := make([]rage.NodeRageInfo, 0)
	for _, n := range nodes.Items {
		// CPU cores: look for cpu capacity, which is in cores (as quantity)
		var cores int32
		if cpuQty, found := n.Status.Capacity[v1.ResourceCPU]; found {
			if v, ok := cpuQty.AsInt64(); ok {
				cores = int32(v)
			} else {
				// fallback: try to parse as milli and divide
				milli := cpuQty.MilliValue()
				cores = int32(milli / 1000)
			}
		}

		var memBytes int64
		if memQty, found := n.Status.Capacity[v1.ResourceMemory]; found {
			memBytes = memQty.Value()
		}

		conds := make([]rage.NodeConditionRageInfo, 0)
		for _, c := range n.Status.Conditions {
			conds = append(conds, rage.NodeConditionRageInfo{
				Type:    string(c.Type),
				Status:  string(c.Status),
				Message: c.Message,
			})
		}

		ni := rage.NodeRageInfo{
			Name:              n.Name,
			Cores:             cores,
			MemoryBytes:       memBytes,
			Conditions:        conds,
			KubernetesVersion: n.Status.NodeInfo.KubeletVersion,
		}

		results = append(results, ni)
	}

	return results, nil
}

func (client *batteryKubeClient) extractHttpRouteInfo(route *unstructured.Unstructured) rage.HttpRouteRageInfo {
	routeInfo := rage.HttpRouteRageInfo{
		Namespace:  route.GetNamespace(),
		Name:       route.GetName(),
		Hostnames:  []string{},
		Conditions: []metav1.Condition{},
	}

	// Extract hostnames from spec
	if spec, found, _ := unstructured.NestedMap(route.Object, "spec"); found {
		if hostnames, found, _ := unstructured.NestedStringSlice(spec, "hostnames"); found {
			routeInfo.Hostnames = hostnames
		}
	}

	// Extract conditions from status
	if status, found, _ := unstructured.NestedMap(route.Object, "status"); found {
		if parents, found, _ := unstructured.NestedSlice(status, "parents"); found && len(parents) > 0 {
			// Get conditions from the first parent
			if parent, ok := parents[0].(map[string]interface{}); ok {
				if conditions, found, _ := unstructured.NestedSlice(parent, "conditions"); found {
					for _, conditionRaw := range conditions {
						if condition, ok := conditionRaw.(metav1.Condition); ok {
							routeInfo.Conditions = append(routeInfo.Conditions, condition)
						}
					}
				}
			}
		}
	}

	return routeInfo
}
