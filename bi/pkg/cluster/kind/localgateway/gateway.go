package localgateway

import (
	"context"
	"net"
)

const (
	noisySocketsImage = "ghcr.io/noisysockets/nsh:v0.8.5"
	// UID/GIDs used by distroless.
	nonRootUID = 65532
	nonRootGID = 65532
)

type Gateway interface {
	Create(ctx context.Context) error
	Destroy(ctx context.Context) error
	Endpoint(ctx context.Context) (string, error)
	GetNetworks(ctx context.Context) ([]*net.IPNet, error)
}
