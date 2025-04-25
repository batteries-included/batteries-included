package kube

import (
	"context"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"golang.org/x/sync/errgroup"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	policyv1 "k8s.io/api/policy/v1"
	apiextensionsv1 "k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1"
	kerrs "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/apimachinery/pkg/runtime/schema"
)

const (
	// maxConcurrentDeletions is the maximum number of resources that can be deleted concurrently.
	maxConcurrentDeletions = 10
	// pollInterval is the interval at which we poll for resource deletion.
	pollInterval = 5 * time.Second
)

func (kubeClient *batteryKubeClient) RemoveAll(ctx context.Context) error {
	// Delete all the resources in the cluster
	// however there's an order that things need to go.

	// 1. First stop the control server so that its reconciler doesn't try to
	// recreate the resources we're about to delete.
	slog.Debug("Stopping control server (if it exists)")

	if err := kubeClient.removeControlServer(ctx); err != nil {
		return fmt.Errorf("failed to stop control server: %w", err)
	}

	// 2. Delete all PodDisruptionBudgets (as they will block draining nodes).
	slog.Debug("Removing pod disruption budgets")

	namespaces, err := kubeClient.client.CoreV1().Namespaces().List(ctx, taggedListOptions())
	if err != nil {
		return fmt.Errorf("failed to list namespaces: %w", err)
	}

	if err := kubeClient.removePodDisruptionBudgets(ctx, namespaces); err != nil {
		return fmt.Errorf("failed to remove pod disruption budgets: %w", err)
	}

	crds, err := kubeClient.apiExtensionsClient.ApiextensionsV1().CustomResourceDefinitions().List(ctx, taggedListOptions())
	if err != nil {
		return fmt.Errorf("failed to list CRDs: %w", err)
	}

	// 3. Delete all namespace-scoped custom resources.
	slog.Debug("Removing namespace scoped custom resources")

	if err := kubeClient.removeNamespacedCustomResources(ctx, namespaces, crds); err != nil {
		return fmt.Errorf("failed to remove namespace-scoped custom resources: %w", err)
	}

	// 4. Delete all cluster-scoped custom resources.
	slog.Debug("Removing cluster scoped custom resources")

	if err := kubeClient.removeClusterScopedCustomResources(ctx, crds); err != nil {
		return fmt.Errorf("failed to remove cluster-scoped custom resources: %w", err)
	}

	// 5. Delete the CRDs themselves.
	slog.Debug("Removing custom resource definitions")

	if err := kubeClient.removeCustomResourceDefinitions(ctx, crds); err != nil {
		return fmt.Errorf("failed to remove custom resource definitions: %w", err)
	}

	// 6. Delete loadbalancer services (that may have allocated EIPs etc).
	slog.Debug("Removing loadbalancer services")

	if err := kubeClient.removeLoadBalancers(ctx, namespaces); err != nil {
		return fmt.Errorf("failed to remove loadbalancer services: %w", err)
	}

	// 7. Delete all batteries included cluster-scoped resources.
	slog.Debug("Removing cluster scoped resources")

	if err := kubeClient.removeClusterScopedResources(ctx); err != nil {
		return fmt.Errorf("failed to remove cluster scoped resources: %w", err)
	}

	// 8. Delete the batteries included namespaces (and all their containing resources).
	slog.Debug("Removing namespaces")

	if err := kubeClient.removeNamespaces(ctx, namespaces); err != nil {
		return fmt.Errorf("failed to remove namespaces: %w", err)
	}

	return nil
}

func (kubeClient *batteryKubeClient) removeControlServer(ctx context.Context) error {
	gvr, err := kubeClient.getGroupVersionResource(&appsv1.Deployment{})
	if err != nil {
		return fmt.Errorf("failed to get GVR for Deployment: %w", err)
	}

	return kubeClient.deleteAndWait(ctx, gvr, "battery-core", "controlserver")
}

func (kubeClient *batteryKubeClient) removePodDisruptionBudgets(ctx context.Context, namespaces *corev1.NamespaceList) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(maxConcurrentDeletions)

	gvr, err := kubeClient.getGroupVersionResource(&policyv1.PodDisruptionBudget{})
	if err != nil {
		return fmt.Errorf("failed to get GVR for PodDisruptionBudget: %w", err)
	}

	for _, ns := range namespaces.Items {
		namespace := ns.Name
		g.Go(func() error {
			pdbs, err := kubeClient.client.PolicyV1().PodDisruptionBudgets(namespace).List(ctx, taggedListOptions())
			if err != nil && !kerrs.IsNotFound(err) {
				return err
			}

			for _, pdb := range pdbs.Items {
				name := pdb.Name
				g.Go(func() error {
					return kubeClient.deleteAndWait(ctx, gvr, namespace, name)
				})
			}

			return nil
		})
	}

	return g.Wait()
}

func (kubeClient *batteryKubeClient) removeNamespacedCustomResources(ctx context.Context, namespaces *corev1.NamespaceList, crds *apiextensionsv1.CustomResourceDefinitionList) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(maxConcurrentDeletions)

	for _, crd := range crds.Items {
		if crd.Spec.Scope == "Namespaced" {
			for _, version := range crd.Spec.Versions {
				gvr := schema.GroupVersionResource{
					Group:    crd.Spec.Group,
					Version:  version.Name,
					Resource: crd.Spec.Names.Plural,
				}

				for _, ns := range namespaces.Items {
					namespace := ns.Name
					g.Go(func() error {
						crList, err := kubeClient.dynamicClient.Resource(gvr).Namespace(namespace).List(ctx, taggedListOptions())
						if err != nil && !kerrs.IsNotFound(err) {
							return err
						}

						// Delete each instance of the namespace-scoped custom resource.
						for _, cr := range crList.Items {
							name := cr.GetName()
							g.Go(func() error {
								return kubeClient.deleteAndWait(ctx, gvr, namespace, name)
							})
						}

						return nil
					})
				}
			}
		}
	}

	return g.Wait()
}

func (kubeClient *batteryKubeClient) removeClusterScopedCustomResources(ctx context.Context, crds *apiextensionsv1.CustomResourceDefinitionList) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(maxConcurrentDeletions)

	for _, crd := range crds.Items {
		if crd.Spec.Scope == "Cluster" {
			for _, version := range crd.Spec.Versions {
				gvr := schema.GroupVersionResource{
					Group:    crd.Spec.Group,
					Version:  version.Name,
					Resource: crd.Spec.Names.Plural,
				}

				g.Go(func() error {
					crList, err := kubeClient.dynamicClient.Resource(gvr).List(ctx, taggedListOptions())
					if err != nil && !kerrs.IsNotFound(err) {
						return err
					}

					// Delete each instance of the cluster-scoped custom resource.
					for _, cr := range crList.Items {
						name := cr.GetName()
						g.Go(func() error {
							return kubeClient.deleteAndWait(ctx, gvr, "", name)
						})
					}

					return nil
				})
			}
		}
	}

	return g.Wait()
}

func (kubeClient *batteryKubeClient) removeCustomResourceDefinitions(ctx context.Context, crds *apiextensionsv1.CustomResourceDefinitionList) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(maxConcurrentDeletions)

	for _, crd := range crds.Items {
		name := crd.GetName()
		g.Go(func() error {
			err := kubeClient.apiExtensionsClient.ApiextensionsV1().CustomResourceDefinitions().Delete(ctx, name, metav1.DeleteOptions{})
			if err != nil && !kerrs.IsNotFound(err) {
				return err
			}

			return nil
		})
	}

	return g.Wait()
}

func (kubeClient *batteryKubeClient) removeLoadBalancers(ctx context.Context, namespaces *corev1.NamespaceList) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(maxConcurrentDeletions)

	gvr, err := kubeClient.getGroupVersionResource(&corev1.Service{})
	if err != nil {
		return fmt.Errorf("failed to get GVR for Service: %w", err)
	}

	for _, ns := range namespaces.Items {
		namespace := ns.Name
		g.Go(func() error {
			services, err := kubeClient.client.CoreV1().Services(namespace).List(ctx, taggedListOptions())
			if err != nil {
				return err
			}

			for _, service := range services.Items {
				if service.Spec.Type == corev1.ServiceTypeLoadBalancer {
					name := service.Name
					g.Go(func() error {
						return kubeClient.deleteAndWait(ctx, gvr, namespace, name)
					})
				}
			}

			return nil
		})
	}

	return g.Wait()
}

func (kubeClient *batteryKubeClient) removeClusterScopedResources(ctx context.Context) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(maxConcurrentDeletions)

	gvrs, err := kubeClient.getClusterScopedGVRs()
	if err != nil {
		return fmt.Errorf("failed to get cluster scoped GVRs: %w", err)
	}

	for _, gvr := range gvrs {
		gvr := gvr
		g.Go(func() error {
			resources, err := kubeClient.dynamicClient.Resource(gvr).List(ctx, taggedListOptions())
			if err != nil {
				// Some internal resources may not be listable/deletable.
				// No matter as these are not created by batteries included.
				if kerrs.IsNotFound(err) || kerrs.IsMethodNotSupported(err) {
					return nil
				}

				return err
			}

			for _, resource := range resources.Items {
				name := resource.GetName()
				g.Go(func() error {
					return kubeClient.deleteAndWait(ctx, gvr, "", name)
				})
			}

			return nil
		})
	}

	return g.Wait()
}

func (kubeClient *batteryKubeClient) removeNamespaces(ctx context.Context, namespaces *corev1.NamespaceList) error {
	g, ctx := errgroup.WithContext(ctx)
	g.SetLimit(maxConcurrentDeletions)

	gvr, err := kubeClient.getGroupVersionResource(&corev1.Namespace{})
	if err != nil {
		return fmt.Errorf("failed to get GVR for Namespace: %w", err)
	}

	for _, ns := range namespaces.Items {
		namespace := ns.Name
		g.Go(func() error {
			return kubeClient.deleteAndWait(ctx, gvr, "", namespace)
		})
	}

	return g.Wait()
}

func (kubeClient *batteryKubeClient) getClusterScopedGVRs() ([]schema.GroupVersionResource, error) {
	apiResourceLists, err := kubeClient.discoveryClient.ServerPreferredResources()
	if err != nil {
		return nil, fmt.Errorf("failed to get API resources: %w", err)
	}

	var clusterScopedGVRs []schema.GroupVersionResource
	for _, apiResourceList := range apiResourceLists {
		for _, apiResource := range apiResourceList.APIResources {
			if !apiResource.Namespaced {
				groupVersion := strings.Split(apiResourceList.GroupVersion, "/")

				var group, version string
				switch len(groupVersion) {
				case 1:
					version = groupVersion[0]
					slog.Error("got version", slog.Any("gv", groupVersion))
				case 2:
					group = groupVersion[0]
					version = groupVersion[1]
					slog.Error("got group version", slog.Any("gv", groupVersion))

				default:
					return nil, fmt.Errorf("unexpected group/version format: %s", apiResourceList.GroupVersion)
				}

				// Treat namespaces as a special case as they are cluster scoped but we
				// want to handle them more specifically.
				if group == "" && apiResource.Name == "namespaces" {
					continue
				}

				// Attempting to list componentstatuses will result in an annoying
				// deprecated warning being logged. We don't care about these resources
				// so we can skip them.
				if group == "" && apiResource.Name == "componentstatuses" {
					continue
				}

				clusterScopedGVRs = append(clusterScopedGVRs, schema.GroupVersionResource{
					Group:    group,
					Version:  version,
					Resource: apiResource.Name,
				})
			}
		}
	}

	return clusterScopedGVRs, nil
}

// deleteAndWait schedules a resource for deletion and waits for it to be deleted.
func (kubeClient *batteryKubeClient) deleteAndWait(ctx context.Context, gvr schema.GroupVersionResource, namespace, name string) error {
	l := slog.With(slog.String("gvr", gvr.String()), slog.String("name", name))

	// Cluster scoped
	deletor := kubeClient.dynamicClient.Resource(gvr).Delete
	msg := "Deleting cluster scoped resource"

	// Namespace scoped.
	if namespace != "" {
		l = l.With(slog.String("namespace", namespace))
		msg = "Deleting namespace scoped resource"
		deletor = kubeClient.dynamicClient.Resource(gvr).Namespace(namespace).Delete
	}

	l.Debug(msg)
	err := deletor(ctx, name, metav1.DeleteOptions{})
	if err != nil {
		// If the resource is not found, it's already been deleted.
		if kerrs.IsNotFound(err) {
			return nil
		}

		return err
	}

	// Poll the resource until it's deleted, we could use a watch here but they get
	// expensive when we have a lot of resources to delete.
	t := time.NewTicker(pollInterval)
	defer t.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-t.C:
		}

		l.Debug("Polling for deletion")

		getter := kubeClient.dynamicClient.Resource(gvr).Get
		if namespace != "" {
			getter = kubeClient.dynamicClient.Resource(gvr).Namespace(namespace).Get
		}

		_, err := getter(ctx, name, metav1.GetOptions{})
		if err != nil {
			if kerrs.IsNotFound(err) {
				l.Debug("Resource deleted")
				return nil
			}

			return fmt.Errorf("failed to poll for deletion: %w", err)
		}
	}
}

func taggedListOptions() metav1.ListOptions {
	return metav1.ListOptions{LabelSelector: labels.Set{"battery/managed": "true"}.String()}
}
