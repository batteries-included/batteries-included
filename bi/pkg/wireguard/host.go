package wireguard

import (
	"fmt"
	"io"
	"strings"

	noisysocketsconfig "github.com/noisysockets/noisysockets/config"
	noisysocketsv1alpha1 "github.com/noisysockets/noisysockets/config/v1alpha1"
	"gopkg.in/ini.v1"
)

// ToHostConfig converts a Noisy Sockets configuration to a WireGuard INI configuration
// (as used by the upstream kernel module).
func ToHostConfig(noisyConfig io.Reader, iniConfig io.Writer) error {
	noisySocketsConfig, err := noisysocketsconfig.FromYAML(noisyConfig)
	if err != nil {
		return fmt.Errorf("failed to read config from reader: %w", err)
	}

	cfg := ini.Empty()

	// Add the [Interface] section.
	ifaceSection, err := cfg.NewSection("Interface")
	if err != nil {
		return fmt.Errorf("failed to add Interface section: %w", err)
	}

	if noisySocketsConfig.ListenPort != 0 {
		if _, err := ifaceSection.NewKey("ListenPort", fmt.Sprintf("%d", noisySocketsConfig.ListenPort)); err != nil {
			return fmt.Errorf("failed to add ListenPort: %w", err)
		}
	}

	if _, err := ifaceSection.NewKey("Address", strings.Join(noisySocketsConfig.IPs, ",")); err != nil {
		return fmt.Errorf("failed to add Address: %w", err)
	}

	if _, err := ifaceSection.NewKey("PrivateKey", noisySocketsConfig.PrivateKey); err != nil {
		return fmt.Errorf("failed to add PrivateKey: %w", err)
	}

	// Do we have a gateway?
	var gatewayPeerConf *noisysocketsv1alpha1.PeerConfig
	for _, peerConf := range noisySocketsConfig.Peers {
		peerConf := peerConf
		if peerConf.DefaultGateway {
			gatewayPeerConf = &peerConf
			break
		}
	}

	if gatewayPeerConf != nil {
		// Add DNS servers.
		if len(noisySocketsConfig.DNSServers) > 0 {
			if _, err := ifaceSection.NewKey("DNS", strings.Join(noisySocketsConfig.DNSServers, ", ")); err != nil {
				return fmt.Errorf("failed to add DNS servers: %w", err)
			}
		}
	}

	// Add the [Peer] sections.
	for _, peerConf := range noisySocketsConfig.Peers {
		peerSection, err := cfg.NewSection("Peer")
		if err != nil {
			return fmt.Errorf("failed to add Peer section: %w", err)
		}

		if peerConf.Name != "" {
			peerSection.Comment = "# " + peerConf.Name
		}

		if _, err := peerSection.NewKey("PublicKey", peerConf.PublicKey); err != nil {
			return fmt.Errorf("failed to add PublicKey: %w", err)
		}

		if len(peerConf.IPs) > 0 {
			if _, err := peerSection.NewKey("AllowedIPs", strings.Join(peerConf.IPs, ",")); err != nil {
				return fmt.Errorf("failed to add AllowedIPs: %w", err)
			}
		} else if peerConf.DefaultGateway {
			// Allow all traffic for gateways.
			if _, err := peerSection.NewKey("AllowedIPs", "0.0.0.0/0,::/0"); err != nil {
				return fmt.Errorf("failed to add AllowedIPs: %w", err)
			}
		}

		if peerConf.Endpoint != "" {
			if _, err := peerSection.NewKey("Endpoint", peerConf.Endpoint); err != nil {
				return fmt.Errorf("failed to add Endpoint: %w", err)
			}
		}
	}

	if _, err := cfg.WriteTo(iniConfig); err != nil {
		return fmt.Errorf("failed to marshal configuration: %w", err)
	}

	return nil
}
