package cluster

import (
	"context"
	"io"
)

type Provider interface {
	Init(context.Context) error
	Create(context.Context) error
	Destroy(context.Context) error
	Outputs(context.Context, io.Writer) error
	// KubeConfig returns the kubeconfig for the cluster.
	// The internal flag indicated we should use an internal address for the cluster
	// (eg. the address you would use from inside the cluster).
	KubeConfig(ctx context.Context, w io.Writer, internal bool) error
	// WireGuardConfig returns the WireGuard configuration for the cluster.
	// The return value indicates if the cluster has WireGuard enabled.
	WireGuardConfig(ctx context.Context, w io.Writer) (hasConfig bool, err error)
}
