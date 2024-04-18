package kube

import (
	"context"
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

	slog.Debug("Removing all resources in cluster")
	err := kubeClient.removeAllHooks(ctx)
	if err != nil {
		return err
	}

	// for all battery namespaces
	namespaces, err := kubeClient.client.CoreV1().Namespaces().List(ctx, taggedListOptions())
	if err != nil {
		slog.Error("Error listing namespaces", slog.Any("error", err))
		return err
	}

	// Remove all the CRD type resources in the cluster
	// These often will remove other resources
	// Remove all the CRD type resources in the cluster
	err = kubeClient.removeAllCRDBackedResources(ctx, namespaces)
	if err != nil {
		return err
	}

	for _, ns := range namespaces.Items {
		err = kubeClient.removeAllInNamespace(ctx, ns)
		if err != nil {
			return err
		}
	}

	// Remove hanging PersistentVolumes
	err = kubeClient.client.CoreV1().
		PersistentVolumes().
		DeleteCollection(
			ctx,
			deleteOptions(),
			taggedListOptions())
	if err != nil {
		return err
	}

	err = kubeClient.removeAllGlobalRBAC(ctx)
	if err != nil {
		return err
	}

	// We have to remove any global RBAC first
	// Before we can remove the service accounts
	// that could have been using the ClusterRoles
	for _, ns := range namespaces.Items {
		// Delete all ServiceAccounts
		err = kubeClient.client.CoreV1().
			ServiceAccounts(ns.Name).
			DeleteCollection(
				ctx,
				deleteOptions(),
				allListOptions())

		if err != nil {
			return err
		}
	}

	// Delete all CustomResourceDefinitions that we added
	err = kubeClient.apiExtensionsClient.ApiextensionsV1().
		CustomResourceDefinitions().
		DeleteCollection(
			ctx,
			deleteOptions(),
			taggedListOptions())
	if err != nil {
		return err
	}

	// Delete All Namespaces
	for _, ns := range namespaces.Items {
		slog.Debug("Removing namespace", slog.String("namespace", ns.Name))
		err = kubeClient.client.CoreV1().
			Namespaces().
			Delete(ctx, ns.Name, deleteOptions())

		if err != nil {
			return err
		}
	}

	return nil
}

func (kubeClient *batteryKubeClient) removeAllHooks(ctx context.Context) error {
	err := kubeClient.client.AdmissionregistrationV1().
		MutatingWebhookConfigurations().
		DeleteCollection(
			ctx,
			deleteOptions(),
			taggedListOptions())

	if err != nil {
		return err
	}

	err = kubeClient.client.AdmissionregistrationV1().
		ValidatingWebhookConfigurations().
		DeleteCollection(
			ctx,
			deleteOptions(),
			taggedListOptions())

	if err != nil {
		return err
	}
	return nil
}

func (kubeClient *batteryKubeClient) removeAllGlobalRBAC(ctx context.Context) error {
	// Now remove the global RBAC
	// Delete all ClusterRoleBindings
	// Delete all ClusterRoles
	err := kubeClient.client.RbacV1().
		ClusterRoleBindings().
		DeleteCollection(
			ctx,
			deleteOptions(),
			taggedListOptions())
	if err != nil {
		return err
	}
	err = kubeClient.client.RbacV1().
		ClusterRoles().
		DeleteCollection(
			ctx,
			deleteOptions(),
			taggedListOptions())
	if err != nil {
		return err
	}
	return nil
}

func (kubeClient *batteryKubeClient) removeAllInNamespace(ctx context.Context, ns v1.Namespace) error {
	slog.Debug("Removing all resources in namespace", slog.String("namespace", ns.Name))

	err := kubeClient.client.AutoscalingV1().
		HorizontalPodAutoscalers(ns.Name).
		DeleteCollection(ctx, deleteOptions(), allListOptions())

	if err != nil {
		return err
	}

	err = kubeClient.client.AppsV1().
		Deployments(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}
	err = kubeClient.client.AppsV1().
		StatefulSets(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}
	err = kubeClient.client.AppsV1().
		DaemonSets(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}
	err = kubeClient.client.AppsV1().
		ReplicaSets(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}
	err = kubeClient.client.BatchV1().
		Jobs(ns.Name).
		DeleteCollection(ctx, deleteOptions(), allListOptions())
	if err != nil {
		return err
	}
	err = kubeClient.client.BatchV1().
		CronJobs(ns.Name).
		DeleteCollection(ctx, deleteOptions(), allListOptions())

	if err != nil {
		return err
	}
	err = kubeClient.client.CoreV1().
		Pods(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}

	err = kubeClient.client.CoreV1().
		ConfigMaps(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}
	err = kubeClient.client.CoreV1().
		Secrets(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}
	err = kubeClient.client.NetworkingV1().
		Ingresses(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}

	err = kubeClient.client.CoreV1().
		PersistentVolumeClaims(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}

	err = kubeClient.client.RbacV1().
		RoleBindings(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}
	err = kubeClient.client.RbacV1().
		Roles(ns.Name).
		DeleteCollection(
			ctx,
			deleteOptions(),
			allListOptions())
	if err != nil {
		return err
	}

	return nil
}

func (kubeClient *batteryKubeClient) removeAllCRDBackedResources(ctx context.Context, namespaces *v1.NamespaceList) error {
	crds, err := kubeClient.apiExtensionsClient.ApiextensionsV1().
		CustomResourceDefinitions().List(ctx, taggedListOptions())
	if err != nil {
		return err
	}

	for _, crd := range crds.Items {
		for _, version := range crd.Spec.Versions {
			gvr := schema.GroupVersionResource{
				Group:    crd.Spec.Group,
				Version:  version.Name,
				Resource: crd.Spec.Names.Plural,
			}

			if crd.Spec.Scope == "Namespaced" {
				slog.Debug("Removing namespaced CRD", slog.Any("kind", gvr))
				for _, ns := range namespaces.Items {
					err = kubeClient.dynamicClient.Resource(gvr).Namespace(ns.Name).
						DeleteCollection(ctx, deleteOptions(), allListOptions())
					if err != nil {
						return err
					}
				}
			} else {
				slog.Debug("Removing cluster CRD", slog.Any("kind", gvr))
				err = kubeClient.dynamicClient.Resource(gvr).
					DeleteCollection(ctx, deleteOptions(), allListOptions())
				if err != nil {
					return err
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
