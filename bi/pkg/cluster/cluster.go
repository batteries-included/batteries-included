package cluster

import (
	"bi/pkg/cluster/util"
	"context"
	"io"
)

type Provider interface {
	// Init initializes the cluster provider (eg. checks for prerequisites and existing state).
	Init(context.Context) error
	// Create creates the cluster (if it doesn't already exist).
	// The progress argument can be used to add a progress bar to the operation.
	// If nil, no progress bar will be shown.
	Create(context.Context, *util.ProgressReporter) error
	// Destroy destroys the cluster (if it exists).
	// The progress argument can be used to add a progress bar to the operation.
	// If nil, no progress bar will be shown.
	Destroy(context.Context, *util.ProgressReporter) error
	// WriteOutputs writes the cluster outputs to the provided writer.
	// This is typically a loosely structured set of key-values encoded in JSON.
	WriteOutputs(context.Context, io.Writer) error
	// WriteKubeConfig returns the kubeconfig for the cluster.
	WriteKubeConfig(ctx context.Context, w io.Writer) error
	// WriteWireGuardConfig returns the WireGuard configuration for the cluster.
	// The return value indicates if the cluster has WireGuard enabled.
	WriteWireGuardConfig(ctx context.Context, w io.Writer) (hasConfig bool, err error)
	// HasNvidiaRuntimeInstalled returns true if NVIDIA runtime was installed during cluster creation.
	HasNvidiaRuntimeInstalled() bool
}
