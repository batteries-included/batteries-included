package wireguard

import (
	"fmt"
	"io"
	"net"
	"net/netip"
	"strings"

	"github.com/apparentlymart/go-cidr/cidr"
	noisysocketstypes "github.com/noisysockets/noisysockets/types"
	"gopkg.in/ini.v1"
)

type Gateway struct {
	// ListenPort is the port that the gateway will listen on.
	ListenPort uint16
	// Address is the internal IP address of the gateway.
	Address netip.Addr
	// Subnet is the subnet cidr that the gateway will use for the WireGuard network.
	Subnet *net.IPNet
	// PrivateKey is the private key of the gateway.
	PrivateKey string
	// DNSServers is a list of DNS servers to use for host resolution.
	DNSServers []netip.Addr
	// Clients is a list of clients that are allowed to connect to the gateway.
	Clients []Client
	// Endpoint is the publicly routable endpoint/address of the gateway.
	Endpoint netip.AddrPort
	// PostUp are a set of commands to run after the interface is brought up.
	PostUp []string
	// PreDown are a set of commands to run before the interface is brought down.
	PreDown []string
}

func NewGateway(listenPort uint16, subnet *net.IPNet) (*Gateway, error) {
	// Generate a new key pair for the gateway.
	privateKey, err := noisysocketstypes.NewPrivateKey()
	if err != nil {
		return nil, fmt.Errorf("failed to generate private key: %w", err)
	}

	// First address in the subnet is reserved for the gateway.
	firstAddress, _ := cidr.AddressRange(subnet)

	// The zero address is reserved in ipv4.
	if v4 := firstAddress.To4(); v4 != nil && v4[3] == 0 {
		firstAddress = cidr.Inc(firstAddress)
	}

	address, _ := netip.AddrFromSlice(firstAddress)

	return &Gateway{
		ListenPort: listenPort,
		Address:    address,
		Subnet:     subnet,
		PrivateKey: privateKey.String(),
	}, nil
}

func (gw *Gateway) NewClient(name string) (*Client, error) {
	// Generate a new key pair for the client.
	privateKey, err := noisysocketstypes.NewPrivateKey()
	if err != nil {
		return nil, fmt.Errorf("failed to generate private key: %w", err)
	}

	var address netip.Addr
	if len(gw.Clients) == 0 {
		nextAddress := cidr.Inc(net.IP(gw.Address.AsSlice()))
		if !gw.Subnet.Contains(nextAddress) {
			return nil, fmt.Errorf("no more addresses available in subnet")
		}

		address, _ = netip.AddrFromSlice(nextAddress)
	} else {
		nextAddress := cidr.Inc(net.IP(gw.Clients[len(gw.Clients)-1].Address.AsSlice()))
		if !gw.Subnet.Contains(nextAddress) {
			return nil, fmt.Errorf("no more addresses available in subnet")
		}

		address, _ = netip.AddrFromSlice(nextAddress)
	}

	c := Client{
		Gateway:    gw,
		Name:       name,
		PrivateKey: privateKey.String(),
		Address:    address,
	}

	gw.Clients = append(gw.Clients, c)

	return &c, nil
}

func (gw *Gateway) WriteConfig(w io.Writer) error {
	cfg := ini.Empty()

	// Add the [Interface] section.
	ifaceSection, err := cfg.NewSection("Interface")
	if err != nil {
		return fmt.Errorf("failed to add Interface section: %w", err)
	}

	if _, err := ifaceSection.NewKey("ListenPort", fmt.Sprintf("%d", gw.ListenPort)); err != nil {
		return fmt.Errorf("failed to add ListenPort key: %w", err)
	}

	if _, err := ifaceSection.NewKey("Address", gw.Address.String()); err != nil {
		return fmt.Errorf("failed to add Address key: %w", err)
	}

	if _, err := ifaceSection.NewKey("PrivateKey", gw.PrivateKey); err != nil {
		return fmt.Errorf("failed to add PrivateKey key: %w", err)
	}

	if len(gw.PostUp) > 0 {
		if _, err := ifaceSection.NewKey("PostUp", strings.Join(gw.PostUp, "; ")); err != nil {
			return fmt.Errorf("failed to add PostUp key: %w", err)
		}
	}
	if len(gw.PreDown) > 0 {
		if _, err := ifaceSection.NewKey("PreDown", strings.Join(gw.PreDown, "; ")); err != nil {
			return fmt.Errorf("failed to add PreDown key: %w", err)
		}
	}

	// Add the [Peer] sections.
	for _, client := range gw.Clients {
		var privateKey noisysocketstypes.NoisePrivateKey
		if err := privateKey.FromString(client.PrivateKey); err != nil {
			return fmt.Errorf("failed to unmarshal client private key: %w", err)
		}

		peerSection, err := cfg.NewSection("Peer")
		if err != nil {
			return fmt.Errorf("failed to add Peer section: %w", err)
		}

		peerSection.Comment = "# " + client.Name
		if _, err := peerSection.NewKey("PublicKey", privateKey.PublicKey().String()); err != nil {
			return fmt.Errorf("failed to add PublicKey key: %w", err)
		}

		if _, err := peerSection.NewKey("AllowedIPs", gw.Subnet.String()); err != nil {
			return fmt.Errorf("failed to add AllowedIPs key: %w", err)
		}
	}

	// Write the marshalled configuration to the writer.
	_, err = cfg.WriteTo(w)
	if err != nil {
		return fmt.Errorf("failed to marshal configuration: %w", err)
	}

	return nil
}
