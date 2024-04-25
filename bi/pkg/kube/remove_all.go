package kube

import (
	"context"
	"fmt"
	"log/slog"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime/schema"

	"k8s.io/apimachinery/pkg/labels"
)

const (
	defaultDeleteGracePeriodSeconds int64 = 900
)

func (kubeClient *batteryKubeClient) RemoveAll(ctx context.Context) error {
	// Delete all the resources in the cluster
	// however there's an order that things need to go.

	slog.Debug("Removing BI managed resources in cluster...")

	slog.Debug("Removing hooks")
	if err := kubeClient.removeAllHooks(ctx); err != nil {
		return fmt.Errorf("unable to remove hooks: %w", err)
	}

	// for all battery namespaces
	namespaces, err := kubeClient.client.CoreV1().Namespaces().List(ctx, taggedListOptions())
	if err != nil {
		return fmt.Errorf("unable to list namespaces: %w", err)
	}

	// Remove all the CRD type resources in the cluster
	// These often will remove other resources
	// Remove all the CRD type resources in the cluster
	if err := kubeClient.removeAllCRDBackedResources(ctx, namespaces); err != nil {
		return fmt.Errorf("unable to remove CRD backed resources: %w", err)
	}

	for _, ns := range namespaces.Items {
		if err := kubeClient.removeAllInNamespace(ctx, ns); err != nil {
			return fmt.Errorf("unable to remove all resources in namespace %s: %w", ns.Name, err)
		}
	}

	slog.Debug("Removing hanging persistent volumes")
	// Remove hanging PersistentVolumes
	err = kubeClient.client.CoreV1().
		PersistentVolumes().
		DeleteCollection(ctx, deleteOptions(), taggedListOptions())
	if err != nil {
		return fmt.Errorf("unable to clean up hanging persistent volumes: %w", err)
	}

	slog.Debug("Removing global RBAC")
	if err := kubeClient.removeAllGlobalRBAC(ctx); err != nil {
		return fmt.Errorf("unable to remove global RBAC: %w", err)
	}

	slog.Debug("Removing service accounts")
	// We have to remove any global RBAC first
	// Before we can remove the service accounts
	// that could have been using the ClusterRoles
	for _, ns := range namespaces.Items {
		// Delete all ServiceAccounts
		err = kubeClient.client.CoreV1().
			ServiceAccounts(ns.Name).
			DeleteCollection(ctx, deleteOptions(), allListOptions())
		if err != nil {
			return fmt.Errorf("unable to remove service accounts in namespace %s: %w", ns.Name, err)
		}
	}

	slog.Debug("Removing custom resource definitions")
	// Delete all CustomResourceDefinitions that we added
	err = kubeClient.apiExtensionsClient.ApiextensionsV1().
		CustomResourceDefinitions().
		DeleteCollection(ctx, deleteOptions(), taggedListOptions())
	if err != nil {
		return fmt.Errorf("unable to remove CRDs: %w", err)
	}

	// Delete All Namespaces
	slog.Debug("Removing namespaces")
	for _, ns := range namespaces.Items {
		slog.Debug("Removing namespace", slog.String("namespace", ns.Name))
		err = kubeClient.client.CoreV1().
			Namespaces().
			Delete(ctx, ns.Name, deleteOptions())
		if err != nil {
			return fmt.Errorf("unable to remove namespace %s: %w", ns.Name, err)
		}
	}

	return nil
}

func (kubeClient *batteryKubeClient) removeAllHooks(ctx context.Context) error {
	err := kubeClient.client.AdmissionregistrationV1().
		MutatingWebhookConfigurations().
		DeleteCollection(ctx, deleteOptions(), taggedListOptions())
	if err != nil {
		return fmt.Errorf("unable to remove mutating webhooks: %w", err)
	}

	err = kubeClient.client.AdmissionregistrationV1().
		ValidatingWebhookConfigurations().
		DeleteCollection(ctx, deleteOptions(), taggedListOptions())
	if err != nil {
		return fmt.Errorf("unable to remove validating webhooks: %w", err)
	}

	return nil
}

func (kubeClient *batteryKubeClient) removeAllGlobalRBAC(ctx context.Context) error {
	// Now remove the global RBAC
	// Delete all ClusterRoleBindings
	// Delete all ClusterRoles
	err := kubeClient.client.RbacV1().
		ClusterRoleBindings().
		DeleteCollection(ctx, deleteOptions(), taggedListOptions())
	if err != nil {
		return fmt.Errorf("unable to remove cluster role bindings: %w", err)
	}

	err = kubeClient.client.RbacV1().
		ClusterRoles().
		DeleteCollection(ctx, deleteOptions(), taggedListOptions())
	if err != nil {
		return fmt.Errorf("unable to remove cluster roles: %w", err)
	}

	return nil
}

func (kubeClient *batteryKubeClient) removeAllInNamespace(ctx context.Context, ns v1.Namespace) error {
	slog.Debug("Removing resources in namespace", slog.String("namespace", ns.Name))

	type collectionDeleter interface {
		DeleteCollection(ctx context.Context, opts metav1.DeleteOptions, listOpts metav1.ListOptions) error
	}

	c := kubeClient.client
	for _, cd := range []collectionDeleter{
		c.AutoscalingV1().HorizontalPodAutoscalers(ns.Name),
		c.AppsV1().Deployments(ns.Name),
		c.AppsV1().StatefulSets(ns.Name),
		c.AppsV1().DaemonSets(ns.Name),
		c.AppsV1().ReplicaSets(ns.Name),
		c.BatchV1().Jobs(ns.Name),
		c.BatchV1().CronJobs(ns.Name),
		c.CoreV1().Pods(ns.Name),
		c.CoreV1().ConfigMaps(ns.Name),
		c.CoreV1().Secrets(ns.Name),
		c.CoreV1().PersistentVolumeClaims(ns.Name),
		c.NetworkingV1().Ingresses(ns.Name),
		c.RbacV1().RoleBindings(ns.Name),
		c.RbacV1().Roles(ns.Name),
	} {
		if err := cd.DeleteCollection(ctx, deleteOptions(), allListOptions()); err != nil {
			return fmt.Errorf("unable to delete %T: %w", cd, err)
		}
	}

	return nil
}

func (kubeClient *batteryKubeClient) removeAllCRDBackedResources(ctx context.Context, namespaces *v1.NamespaceList) error {
	slog.Debug("Removing custom resources")
	opts := taggedListOptions()
	var timeout int64 = 45
	opts.TimeoutSeconds = &timeout
	crds, err := kubeClient.apiExtensionsClient.ApiextensionsV1().CustomResourceDefinitions().List(ctx, opts)
	if err != nil {
		return fmt.Errorf("unable to list CRDs: %w", err)
	}

	for _, crd := range crds.Items {
		for _, version := range crd.Spec.Versions {
			gvr := schema.GroupVersionResource{
				Group:    crd.Spec.Group,
				Version:  version.Name,
				Resource: crd.Spec.Names.Plural,
			}

			if crd.Spec.Scope == "Namespaced" {
				slog.Debug("Removing namespaced CR", slog.Any("kind", gvr))
				for _, ns := range namespaces.Items {
					err = kubeClient.dynamicClient.Resource(gvr).Namespace(ns.Name).
						DeleteCollection(ctx, deleteOptions(), allListOptions())
					if err != nil {
						return fmt.Errorf("unable to remove namespaced CRD %q: %w", gvr, err)
					}
				}
			} else {
				slog.Debug("Removing cluster CR", slog.Any("kind", gvr))
				err = kubeClient.dynamicClient.Resource(gvr).DeleteCollection(ctx, deleteOptions(), allListOptions())
				if err != nil {
					return fmt.Errorf("unable to remove cluster CRD %q: %w", gvr, err)
				}
			}
		}
	}
	return nil
}

func deleteOptions() metav1.DeleteOptions {
	gracePeriod := defaultDeleteGracePeriodSeconds
	propagationPolicy := metav1.DeletePropagationForeground
	return metav1.DeleteOptions{GracePeriodSeconds: &gracePeriod, PropagationPolicy: &propagationPolicy}
}

func taggedListOptions() metav1.ListOptions {
	return metav1.ListOptions{LabelSelector: labels.Set{"battery/managed": "true"}.String()}
}

func allListOptions() metav1.ListOptions {
	return metav1.ListOptions{}
}
