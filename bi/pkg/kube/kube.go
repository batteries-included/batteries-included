package kube

import (
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"os"

	"github.com/noisysockets/noisysockets"
	noisysocketsconfig "github.com/noisysockets/noisysockets/config"
	"github.com/noisysockets/noisysockets/network"
	apiextensionsclientset "k8s.io/apiextensions-apiserver/pkg/client/clientset/clientset"
	cacheddiscovery "k8s.io/client-go/discovery/cached/memory"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/restmapper"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/portforward"
	"k8s.io/client-go/transport"
)

type KubeClient interface {
	io.Closer
	EnsureResourceExists(resource map[string]interface{}) error
	PortForwardService(
		namespace string,
		name string,
		port int,
		localPort int,
		stopChannel <-chan struct{},
		readyChannel chan struct{}) (*portforward.PortForwarder, error)
	RemoveAll() error
}

type batteryKubeClient struct {
	cfg                 *rest.Config
	client              *kubernetes.Clientset
	dynamicClient       *dynamic.DynamicClient
	apiExtensionsClient *apiextensionsclientset.Clientset
	mapper              *restmapper.DeferredDiscoveryRESTMapper
	net                 network.Network
}

func NewBatteryKubeClient(kubeConfigPath, wireGuardConfigPath string) (KubeClient, error) {
	slog.Debug("Creating new kubernetes client",
		slog.String("kubeConfigPath", kubeConfigPath),
		slog.String("wireGuardConfigPath", wireGuardConfigPath))

	kubeConfig, err := clientcmd.BuildConfigFromFlags("", kubeConfigPath)
	if err != nil {
		return nil, fmt.Errorf("error building kube config: %w", err)
	}

	// This is normally called automatically by the client-go library, but we need to do it manually
	// due to using our own transport.
	if kubeConfig.UserAgent == "" {
		kubeConfig.UserAgent = rest.DefaultKubernetesUserAgent()
	}

	var net network.Network
	var httpClient *http.Client
	if wireGuardConfigPath != "" {
		httpClient, err = rest.HTTPClientFor(kubeConfig)
		if err != nil {
			return nil, fmt.Errorf("error creating http client: %w", err)
		}

		// Read the wireguard config
		wireGuardConfigFile, err := os.Open(wireGuardConfigPath)
		if err != nil {
			return nil, fmt.Errorf("error opening wireguard config: %w", err)
		}
		defer wireGuardConfigFile.Close()

		wireGuardConfig, err := noisysocketsconfig.FromYAML(wireGuardConfigFile)
		if err != nil {
			return nil, fmt.Errorf("error reading wireguard config: %w", err)
		}

		// Connect to the wireguard gateway
		net, err = noisysockets.NewNetwork(slog.Default(), wireGuardConfig)
		if err != nil {
			return nil, fmt.Errorf("error opening wireguard network: %w", err)
		}

		// Create a http client that will send all requests over wireguard
		transportConfig, err := kubeConfig.TransportConfig()
		if err != nil {
			return nil, fmt.Errorf("error getting transport config: %w", err)
		}

		transportConfig.DialHolder = &transport.DialHolder{
			Dial: net.DialContext,
		}

		// Replace the transport with our own wireguard based transport
		httpClient.Transport, err = transport.New(transportConfig)
		if err != nil {
			return nil, fmt.Errorf("error creating http transport: %w", err)
		}
	} else {
		// No wireguard config, assume we are accessing a local cluster without a gateway
		httpClient, err = rest.HTTPClientFor(kubeConfig)
		if err != nil {
			return nil, fmt.Errorf("error creating http client: %w", err)
		}
	}

	// Create a new kubernetes client for discovery and watching job results
	client, err := kubernetes.NewForConfigAndClient(kubeConfig, httpClient)
	if err != nil {
		return nil, fmt.Errorf("error creating kubernetes client: %w", err)
	}

	// Dynamic client for creating resources from intial resources
	dynamicClient, err := dynamic.NewForConfigAndClient(kubeConfig, httpClient)
	if err != nil {
		return nil, fmt.Errorf("error creating kubernetes dynamic client: %w", err)
	}

	// The discovery client is used to get the GroupVersionResource
	discoveryClient := cacheddiscovery.NewMemCacheClient(client.Discovery())
	mapper := restmapper.NewDeferredDiscoveryRESTMapper(discoveryClient)

	// This allows us to remove CRD's
	apiextensionsclient, err := apiextensionsclientset.NewForConfig(kubeConfig)
	if err != nil {
		return nil, err
	}

	return &batteryKubeClient{
		cfg:                 kubeConfig,
		client:              client,
		dynamicClient:       dynamicClient,
		mapper:              mapper,
		net:                 net,
		apiExtensionsClient: apiextensionsclient}, nil
}

func (c *batteryKubeClient) Close() error {
	if c.net != nil {
		if err := c.net.Close(); err != nil {
			return fmt.Errorf("error closing wireguard network: %w", err)
		}
	}

	return nil
}
