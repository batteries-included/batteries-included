package kube

import (
	"bi/pkg/access"
	"bi/pkg/rage"
	"context"
	"fmt"
	"io"
	"log/slog"
	"net"
	"os"
	"time"

	"github.com/noisysockets/network"
	"github.com/noisysockets/noisysockets"
	noisysocketsconfig "github.com/noisysockets/noisysockets/config"
	apiextensionsclientset "k8s.io/apiextensions-apiserver/pkg/client/clientset/clientset"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/discovery"
	cacheddiscovery "k8s.io/client-go/discovery/cached/memory"
	"k8s.io/client-go/dynamic"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/restmapper"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/portforward"
)

type KubeClient interface {
	io.Closer
	EnsureResourceExists(ctx context.Context, resource map[string]interface{}) error
	PortForwardService(
		ctx context.Context,
		namespace string,
		name string,
		port int,
		localPort int,
		stopChannel <-chan struct{},
		readyChannel chan struct{}) (*portforward.PortForwarder, error)
	RemoveAll(ctx context.Context) error
	WaitForConnection(time.Duration) error
	WatchFor(context.Context, *WatchOptions) error
	GetAccessInfo(ctx context.Context, namespace string) (*access.AccessSpec, error)
	GetPostgresAccessInfo(ctx context.Context, namespace string, clusterName string, userName string) (*access.PostgresAccessSpec, error)
	ListPodsRage(ctx context.Context) ([]rage.PodRageInfo, error)
	ListHttpRoutesRage(ctx context.Context) ([]rage.HttpRouteRageInfo, error)
	ListNodesRage(ctx context.Context) ([]rage.NodeRageInfo, error)
	GetDialContext() func(ctx context.Context, network, address string) (net.Conn, error)
}

type batteryKubeClient struct {
	cfg                 *rest.Config
	client              *kubernetes.Clientset
	dynamicClient       *dynamic.DynamicClient
	apiExtensionsClient *apiextensionsclientset.Clientset
	discoveryClient     discovery.CachedDiscoveryInterface
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

	// Set the QPS and Burst to the maximum values to avoid client-side rate
	// limiting when rapidly creating and deleting resources.
	kubeConfig.QPS = 50
	kubeConfig.Burst = 100

	var net network.Network
	if wireGuardConfigPath != "" {
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
		net, err = noisysockets.OpenNetwork(slog.Default(), wireGuardConfig)
		if err != nil {
			return nil, fmt.Errorf("error opening wireguard network: %w", err)
		}

		// Turns out we can just set a net.Dialer on the *rest.Config.
		kubeConfig.Dial = net.DialContext
	}

	// Create a new kubernetes client for discovery and watching job results
	client, err := kubernetes.NewForConfig(kubeConfig)
	if err != nil {
		return nil, fmt.Errorf("error creating kubernetes client: %w", err)
	}

	// Dynamic client for creating resources from intial resources
	dynamicClient, err := dynamic.NewForConfig(kubeConfig)
	if err != nil {
		return nil, fmt.Errorf("error creating kubernetes dynamic client: %w", err)
	}

	// The discovery client is used to get the GroupVersionResource
	discoveryClient := cacheddiscovery.NewMemCacheClient(client.Discovery())
	mapper := restmapper.NewDeferredDiscoveryRESTMapper(discoveryClient)

	// This allows us to remove CRD's
	apiextensionsclient, err := apiextensionsclientset.NewForConfig(kubeConfig)
	if err != nil {
		return nil, fmt.Errorf("error creating apiextensions client: %w", err)
	}

	return &batteryKubeClient{
		cfg:                 kubeConfig,
		client:              client,
		dynamicClient:       dynamicClient,
		discoveryClient:     discoveryClient,
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

func (c *batteryKubeClient) WaitForConnection(timeout time.Duration) error {
	done := make(chan struct{})
	timer := time.AfterFunc(timeout, func() {
		done <- struct{}{}
	})
	defer timer.Stop()

	for {
		select {
		case <-done:
			return fmt.Errorf("timed out waiting for cluster to be ready")
		default:
			_, err := c.client.Discovery().OpenAPISchema()
			if err == nil {
				slog.Info("Successfully connected to cluster")
				return nil
			}
			slog.Debug("Still waiting on cluster to be ready")
			time.Sleep(1 * time.Second)
		}
	}
}

type WatchOptions struct {
	// The desired Group, Version, Resource for the watch
	GVR schema.GroupVersionResource
	// Namespace of the resource(s) to watch
	Namespace string
	// The list options for the watch. Specify the resources to watch here
	ListOpts metav1.ListOptions
	// The callback to run against each event.
	Callback func(*unstructured.Unstructured) (done bool, err error)
}

func (c *batteryKubeClient) WatchFor(ctx context.Context, opts *WatchOptions) error {
	watch, err := c.dynamicClient.Resource(opts.GVR).Namespace(opts.Namespace).Watch(ctx, opts.ListOpts)
	if err != nil {
		return fmt.Errorf("failed to create watch: %w", err)
	}

	for event := range watch.ResultChan() {
		u, ok := event.Object.(*unstructured.Unstructured)
		if !ok {
			slog.Debug("Got unexpected event", slog.String("objectType", fmt.Sprintf("%T", event.Object)))
			continue
		}

		slog.Debug("Received watch event", slog.String("eventType", string(event.Type)))

		done, err := opts.Callback(u)
		if err != nil {
			return err
		}
		if done {
			watch.Stop()
		}
	}
	return nil
}

func (c *batteryKubeClient) GetDialContext() func(ctx context.Context, network, address string) (net.Conn, error) {
	if c.net != nil {
		return c.net.DialContext
	}
	return nil
}
