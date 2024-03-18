package kube

import (
	"context"
	"fmt"
	"log/slog"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	cacheddiscovery "k8s.io/client-go/discovery/cached/memory"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/restmapper"
	"k8s.io/client-go/tools/clientcmd"
)

type KubeClient interface {
	EnsureReourceExists(resource map[string]interface{}) error
}

type batteryKubeClient struct {
	cfg           *rest.Config
	client        *kubernetes.Clientset
	dynamicClient *dynamic.DynamicClient
	mapper        *restmapper.DeferredDiscoveryRESTMapper
}

func NewBatteryKubeClient(kubeConfigPath string) (KubeClient, error) {
	slog.Debug("Creating new kubernetes client", slog.String("kubeConfigPath", kubeConfigPath))
	cfg, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
	if err != nil {
		panic(err)
	}

	// TODO create a new http dynamicClient that uses
	// the wireguard tunnel to connect to the cluster

	// Create a new kubernetes client for discovery and watching job results
	client, err := kubernetes.NewForConfig(cfg)
	if err != nil {
		return nil, err
	}

	// Dynamic client for creating resources from intial resources
	dynamicClient, err := dynamic.NewForConfig(cfg)
	if err != nil {
		return nil, err
	}

	// The discovery client is used to get the GroupVersionResource
	discoveryClient := cacheddiscovery.NewMemCacheClient(client.Discovery())
	mapper := restmapper.NewDeferredDiscoveryRESTMapper(discoveryClient)

	return &batteryKubeClient{cfg: cfg, client: client, dynamicClient: dynamicClient, mapper: mapper}, nil
}

func (batteryKube *batteryKubeClient) EnsureReourceExists(resource map[string]interface{}) error {
	unstructuredResource := &unstructured.Unstructured{Object: resource}

	err := batteryKube.exists(unstructuredResource)

	if err != nil {
		return batteryKube.create(unstructuredResource)
	}
	return nil
}

func (batteryKube *batteryKubeClient) exists(unstructuredResource *unstructured.Unstructured) error {
	ns := unstructuredResource.GetNamespace()
	name := unstructuredResource.GetName()
	gvr, err := batteryKube.getGroupVersionResource(unstructuredResource)
	if err != nil {
		return err
	}

	if ns == "" {
		_, err = batteryKube.dynamicClient.Resource(gvr).Get(context.TODO(), name, metav1.GetOptions{})
	} else {
		_, err = batteryKube.dynamicClient.Resource(gvr).Namespace(ns).Get(context.TODO(), name, metav1.GetOptions{})
	}

	if err != nil {
		slog.Debug("Resource does not exist or other error",
			slog.String("name", name),
			slog.String("namespace", ns),
			slog.String("kind", unstructuredResource.GetKind()),
			slog.Any("error", err))

		return err
	}

	slog.Debug("Resource exists",
		slog.String("name", name),
		slog.String("namespace", ns),
		slog.String("kind", unstructuredResource.GetKind()))
	return nil
}

func (batteryKube *batteryKubeClient) create(unstructuredResource *unstructured.Unstructured) error {
	ns := unstructuredResource.GetNamespace()
	gvr, err := batteryKube.getGroupVersionResource(unstructuredResource)
	if err != nil {
		return err
	}

	if ns == "" {
		_, err = batteryKube.dynamicClient.Resource(gvr).Create(context.TODO(), unstructuredResource, metav1.CreateOptions{})
	} else {
		_, err = batteryKube.dynamicClient.Resource(gvr).Namespace(ns).Create(context.TODO(), unstructuredResource, metav1.CreateOptions{})
	}
	if err != nil {
		return err
	}

	slog.Debug("Resource created",
		slog.String("namespace", ns),
		slog.String("name", unstructuredResource.GetName()),
		slog.String("kind", unstructuredResource.GetKind()),
	)
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
