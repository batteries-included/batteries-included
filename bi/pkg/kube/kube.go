package kube

import (
	"log/slog"

	cacheddiscovery "k8s.io/client-go/discovery/cached/memory"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/restmapper"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/portforward"
)

type KubeClient interface {
	EnsureReourceExists(resource map[string]interface{}) error
	PortForwardService(
		namespace string,
		name string,
		port int,
		localPort int,
		stopChannel <-chan struct{},
		readyChannel chan struct{}) (*portforward.PortForwarder, error)
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
