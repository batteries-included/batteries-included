package wireguard

import (
	"fmt"
	"io"
	"net"
	"net/netip"
	"strings"

	"github.com/apparentlymart/go-cidr/cidr"
	noisysocketsconfig "github.com/noisysockets/noisysockets/config"
	noisysocketsv1alpha2 "github.com/noisysockets/noisysockets/config/v1alpha2"
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
	// Nameservers is a list of DNS servers to use for host resolution.
	Nameservers []netip.Addr
	// Clients is a list of clients that are allowed to connect to the gateway.
	Clients []Client
	// Endpoint is the publicly routable endpoint/address of the gateway.
	Endpoint string
	// PostUp are a set of commands to run after the interface is brought up.
	PostUp []string
	// PreDown are a set of commands to run before the interface is brought down.
	PreDown []string
	// VPCSubnets is a list of subnets that the gateway can route traffic to.
	VPCSubnets []*net.IPNet
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

	// by default, the first address after gw address
	nextAddress := cidr.Inc(net.IP(gw.Address.AsSlice()))
	// if there are clients, use the next address after the last client
	if len(gw.Clients) > 0 {
		nextAddress = cidr.Inc(net.IP(gw.Clients[len(gw.Clients)-1].Address.AsSlice()))
	}

	if !gw.Subnet.Contains(nextAddress) {
		return nil, fmt.Errorf("no more addresses available in subnet")
	}

	address, _ := netip.AddrFromSlice(nextAddress)

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
	conf := &noisysocketsv1alpha2.Config{
		Name:       "gateway",
		ListenPort: gw.ListenPort,
		PrivateKey: gw.PrivateKey,
		IPs:        []string{gw.Address.String()},
	}

	for _, client := range gw.Clients {
		var privateKey noisysocketstypes.NoisePrivateKey
		if err := privateKey.UnmarshalText([]byte(client.PrivateKey)); err != nil {
			return fmt.Errorf("failed to unmarshal client private key: %w", err)
		}

		conf.Peers = append(conf.Peers, noisysocketsv1alpha2.PeerConfig{
			Name:      client.Name,
			PublicKey: privateKey.Public().String(),
			IPs:       []string{client.Address.String()},
		})
	}

	var sb strings.Builder
	if err := noisysocketsconfig.ToINI(&sb, conf); err != nil {
		return fmt.Errorf("failed to marshal configuration: %w", err)
	}

	iniConf, err := ini.LoadSources(ini.LoadOptions{AllowNonUniqueSections: true}, strings.NewReader(sb.String()))
	if err != nil {
		return fmt.Errorf("failed to parse INI config: %w", err)
	}

	ifaceSection, err := iniConf.GetSection("Interface")
	if err != nil {
		return fmt.Errorf("failed to get interface section: %w", err)
	}

	// Add any PostUp and PreDown commands (which are not supported by noisysockets).
	if len(gw.PostUp) > 0 {
		if _, err := ifaceSection.NewKey("PostUp", strings.Join(gw.PostUp, "; ")); err != nil {
			return fmt.Errorf("failed to add PostUp: %w", err)
		}
	}

	if len(gw.PreDown) > 0 {
		if _, err := ifaceSection.NewKey("PreDown", strings.Join(gw.PreDown, "; ")); err != nil {
			return fmt.Errorf("failed to add PreDown: %w", err)
		}
	}

	if _, err := iniConf.WriteTo(w); err != nil {
		return fmt.Errorf("failed to marshal configuration: %w", err)
	}

	return nil
}

func (gw *Gateway) WriteNoisySocketsConfig(w io.Writer) error {
	conf := &noisysocketsv1alpha2.Config{
		Name:       "gateway",
		ListenPort: gw.ListenPort,
		PrivateKey: gw.PrivateKey,
		IPs:        []string{gw.Address.String()},
	}

	for _, client := range gw.Clients {
		var privateKey noisysocketstypes.NoisePrivateKey
		if err := privateKey.UnmarshalText([]byte(client.PrivateKey)); err != nil {
			return fmt.Errorf("failed to unmarshal client private key: %w", err)
		}

		conf.Peers = append(conf.Peers, noisysocketsv1alpha2.PeerConfig{
			Name:      client.Name,
			PublicKey: privateKey.Public().String(),
			IPs:       []string{client.Address.String()},
		})
	}

	if err := noisysocketsconfig.ToYAML(w, conf); err != nil {
		return fmt.Errorf("failed to marshal configuration: %w", err)
	}

	return nil
}
