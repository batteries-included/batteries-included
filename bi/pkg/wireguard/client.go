package wireguard

import (
	"fmt"
	"io"
	"net/netip"

	noisysocketsconfig "github.com/noisysockets/noisysockets/config"
	noisysocketsv1alpha2 "github.com/noisysockets/noisysockets/config/v1alpha2"
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
	var nameservers []string
	for _, ns := range c.Gateway.Nameservers {
		nameservers = append(nameservers, ns.String())
	}

	var privateKey noisysocketstypes.NoisePrivateKey
	if err := privateKey.UnmarshalText([]byte(c.Gateway.PrivateKey)); err != nil {
		return fmt.Errorf("failed to unmarshal gateway private key: %w", err)
	}

	conf := &noisysocketsv1alpha2.Config{
		Name:       c.Name,
		PrivateKey: c.PrivateKey,
		IPs:        []string{c.Address.String()},
		DNS: &noisysocketsv1alpha2.DNSConfig{
			Servers: nameservers,
		},
		Peers: []noisysocketsv1alpha2.PeerConfig{
			{
				Name:      "gateway",
				PublicKey: privateKey.Public().String(),
				Endpoint:  c.Gateway.Endpoint,
				IPs:       []string{c.Gateway.Address.String()},
			},
		},
	}

	for _, subnet := range c.Gateway.VPCSubnets {
		conf.Routes = append(conf.Routes, noisysocketsv1alpha2.RouteConfig{
			Destination: subnet.String(),
			Via:         "gateway",
		})
	}

	// Given we are using an internal Route53 resolver (on its own subnet), we
	// need to add the nameserver routes to the client config.
	for _, ns := range c.Gateway.Nameservers {
		if ns.String() == c.Gateway.Address.String() {
			continue
		}

		conf.Routes = append(conf.Routes, noisysocketsv1alpha2.RouteConfig{
			Destination: netip.PrefixFrom(ns, ns.BitLen()).String(),
			Via:         "gateway",
		})
	}

	return noisysocketsconfig.ToYAML(w, conf)
}
