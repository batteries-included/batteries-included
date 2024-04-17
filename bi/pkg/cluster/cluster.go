package cluster

import (
	"context"
	"io"
)

type Provider interface {
	// Init initializes the cluster provider (eg. checks for prerequisites and existing state).
	Init(context.Context) error
	// Create creates the cluster (if it doesn't already exist).
	Create(context.Context) error
	// Destroy destroys the cluster (if it exists).
	Destroy(context.Context) error
	// Outputs writes the cluster outputs to the provided writer.
	// This is typically a loosely structured set of key-values encoded in JSON.
	Outputs(context.Context, io.Writer) error
	// KubeConfig returns the kubeconfig for the cluster.
	// The internal flag indicated we should use an internal address for the cluster
	// (eg. the address you would use from inside the cluster).
	KubeConfig(ctx context.Context, w io.Writer, internal bool) error
	// WireGuardConfig returns the WireGuard configuration for the cluster.
	// The return value indicates if the cluster has WireGuard enabled.
	WireGuardConfig(ctx context.Context, w io.Writer) (hasConfig bool, err error)
}
