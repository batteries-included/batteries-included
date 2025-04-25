package kube

import (
	"context"
	"fmt"
	"log/slog"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/kubernetes/scheme"
)

func (batteryKube *batteryKubeClient) EnsureResourceExists(ctx context.Context, resource map[string]interface{}) error {
	unstructuredResource := &unstructured.Unstructured{Object: resource}

	if err := batteryKube.exists(ctx, unstructuredResource); err != nil {
		return batteryKube.create(ctx, unstructuredResource)
	}

	return nil
}

func (batteryKube *batteryKubeClient) exists(ctx context.Context, unstructuredResource *unstructured.Unstructured) error {
	ns := unstructuredResource.GetNamespace()
	name := unstructuredResource.GetName()
	gvr, err := batteryKube.getGroupVersionResource(unstructuredResource)
	if err != nil {
		return fmt.Errorf("failed to get gvr: %w", err)
	}

	logger := slog.With("name", name, "namespace", ns, "kind", unstructuredResource.GetKind())

	getter := batteryKube.dynamicClient.Resource(gvr).Get
	if ns != "" {
		getter = batteryKube.dynamicClient.Resource(gvr).Namespace(ns).Get
	}

	_, err = getter(ctx, name, metav1.GetOptions{})
	if err != nil {
		logger.Debug("Resource does not exist or other error", slog.Any("error", err))
		return fmt.Errorf("failed to get resource: %w", err)
	}

	logger.Debug("Resource exists")
	return nil
}

func (batteryKube *batteryKubeClient) create(ctx context.Context, unstructuredResource *unstructured.Unstructured) error {
	ns := unstructuredResource.GetNamespace()
	gvr, err := batteryKube.getGroupVersionResource(unstructuredResource)
	if err != nil {
		return fmt.Errorf("failed to get gvr: %w", err)
	}

	logger := slog.With("namespace", ns, "kind", unstructuredResource.GetKind())

	creator := batteryKube.dynamicClient.Resource(gvr).Create
	if ns != "" {
		creator = batteryKube.dynamicClient.Resource(gvr).Namespace(ns).Create
	}

	_, err = creator(ctx, unstructuredResource, metav1.CreateOptions{})
	if err != nil {
		logger.Debug("Failed to create resource", slog.Any("error", err))
		return fmt.Errorf("failed to create resource: %w", err)
	}

	logger.Debug("Resource created")
	return nil
}

func (batteryKube *batteryKubeClient) getGroupVersionResource(resource runtime.Object) (schema.GroupVersionResource, error) {
	// Kubernetes does a stupid thing where it tries to pretend that it's able to speak many different
	// versions of the same resource. This is a lie, and it's a lie that we have to deal with.
	// So we do this complicated dance to get the exact Group Version that the server
	// will return for a given resource.
	//
	// Yes I am bitter about the complexity.
	// Yes I think this is lame.
	// No I don't have a better solution.
	//
	// Get the ObjectKinds for the already wrapped map[string]interface{}
	// Then use that to try and get the RESTMapping for the resource
	// through a caching discovery client
	kinds, _, _ := scheme.Scheme.ObjectKinds(resource)
	if len(kinds) != 1 {
		return schema.GroupVersionResource{}, fmt.Errorf("bad kinds")
	}
	gvk := kinds[0]

	restMapping, err := batteryKube.mapper.RESTMapping(gvk.GroupKind(), gvk.Version)
	if err != nil {
		return schema.GroupVersionResource{}, err
	}

	return restMapping.Resource, nil
}
