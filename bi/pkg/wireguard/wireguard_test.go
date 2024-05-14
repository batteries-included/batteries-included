package wireguard_test

import (
	"fmt"
	"net"
	"net/netip"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"bi/pkg/wireguard"

	noisysocketsconfig "github.com/noisysockets/noisysockets/config"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gopkg.in/ini.v1"
)

func TestWireGuardConfig(t *testing.T) {
	listenPort := uint16(51820)
	nameservers := []netip.Addr{
		netip.MustParseAddr("100.64.250.1"),
	}
	endpoint := netip.MustParseAddrPort("127.0.0.1:51820")

	_, subnet, err := net.ParseCIDR("100.64.250.0/24")
	require.NoError(t, err)

	gw, err := wireguard.NewGateway(listenPort, subnet)
	require.NoError(t, err)

	gw.Nameservers = nameservers
	gw.Endpoint = endpoint
	gw.PostUp = []string{
		"iptables -A FORWARD -i wg0 -j ACCEPT",
		"iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE",
	}
	gw.PreDown = []string{
		"iptables -D FORWARD -i wg0 -j ACCEPT",
		"iptables -t nat -D POSTROUTING -o ens5 -j MASQUERADE",
	}

	c, err := gw.NewClient("installer")
	require.NoError(t, err)

	var gwConfig strings.Builder
	require.NoError(t, gw.WriteConfig(&gwConfig))

	cfg, err := ini.Load([]byte(gwConfig.String()))
	require.NoError(t, err)

	ifaceSection, err := cfg.GetSection("Interface")
	require.NoError(t, err)

	assert.Equal(t, fmt.Sprintf("%d", listenPort), ifaceSection.Key("ListenPort").String())
	assert.Equal(t, "100.64.250.1", ifaceSection.Key("Address").String())
	assert.NotEmpty(t, ifaceSection.Key("PrivateKey").String())

	postUpCmds := ifaceSection.Key("PostUp").Strings(";")
	assert.Len(t, postUpCmds, 2)

	preDownCmds := ifaceSection.Key("PreDown").Strings(";")
	assert.Len(t, preDownCmds, 2)

	peerSections, err := cfg.SectionsByName("Peer")
	require.NoError(t, err)

	require.Len(t, peerSections, 1)
	assert.NotEmpty(t, peerSections[0].Key("PublicKey").String())
	assert.Equal(t, "100.64.250.2", peerSections[0].Key("AllowedIPs").String())

	configPath := filepath.Join(t.TempDir(), "wireguard.yaml")

	clientConfigFile, err := os.Create(configPath)
	require.NoError(t, err)

	require.NoError(t, c.WriteConfig(clientConfigFile))

	require.NoError(t, clientConfigFile.Close())

	configFile, err := os.Open(configPath)
	require.NoError(t, err)
	t.Cleanup(func() {
		require.NoError(t, configFile.Close())
	})

	clientConfig, err := noisysocketsconfig.FromYAML(configFile)
	require.NoError(t, err)

	assert.Equal(t, c.Name, clientConfig.Name)
	assert.Equal(t, c.PrivateKey, clientConfig.PrivateKey)
	assert.Equal(t, []string{c.Address.String()}, clientConfig.IPs)

	require.Len(t, clientConfig.Peers, 1)
	assert.Equal(t, "gateway", clientConfig.Peers[0].Name)
	assert.Equal(t, []string{"100.64.250.1"}, clientConfig.Peers[0].IPs)
	assert.Equal(t, endpoint.String(), clientConfig.Peers[0].Endpoint)
}
