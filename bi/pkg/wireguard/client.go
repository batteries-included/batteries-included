package wireguard

import (
	"fmt"
	"io"
	"net/netip"

	"github.com/noisysockets/noisysockets/config"
	noisysocketsconfigtypes "github.com/noisysockets/noisysockets/config/types"
	noisysocketsv1alpha1 "github.com/noisysockets/noisysockets/config/v1alpha1"
	noisysocketstypes "github.com/noisysockets/noisysockets/types"
)

type Client struct {
	// Gateway is the gateway that the client connects to.
	Gateway *Gateway
	// Name is the human-readable name of the client.
	Name string
	// PrivateKey is the private key of the client.
	PrivateKey string
	// Address is the internal IP address assigned to the client.
	Address netip.Addr
}

// WriteConfig saves a client WireGuard configuration to the given writer.
func (c *Client) WriteConfig(w io.Writer) error {
	var dnsServers []string
	for _, dnsServer := range c.Gateway.DNSServers {
		dnsServers = append(dnsServers, dnsServer.String())
	}

	var privateKey noisysocketstypes.NoisePrivateKey
	if err := privateKey.FromString(c.Gateway.PrivateKey); err != nil {
		return fmt.Errorf("failed to unmarshal gateway private key: %w", err)
	}

	conf := &noisysocketsv1alpha1.Config{
		TypeMeta: noisysocketsconfigtypes.TypeMeta{
			APIVersion: noisysocketsv1alpha1.ApiVersion,
			Kind:       "Config",
		},
		Name:       c.Name,
		PrivateKey: c.PrivateKey,
		IPs:        []string{c.Address.String()},
		DNSServers: dnsServers,
		Peers: []noisysocketsv1alpha1.PeerConfig{
			{
				Name:           "gateway",
				PublicKey:      privateKey.PublicKey().String(),
				Endpoint:       c.Gateway.Endpoint.String(),
				IPs:            []string{c.Gateway.Address.String()},
				DefaultGateway: true,
			},
		},
	}

	return config.SaveToYAML(w, conf)
}
