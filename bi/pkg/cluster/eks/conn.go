package eks

import (
	"fmt"
	"net"
	"net/netip"

	"github.com/apparentlymart/go-cidr/cidr"
	"github.com/jsimonetti/rtnetlink/rtnl"
	"github.com/pulumi/pulumi/sdk/v3/go/auto"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"golang.zx2c4.com/wireguard/conn"
	"golang.zx2c4.com/wireguard/device"
	"golang.zx2c4.com/wireguard/ipc"
	"golang.zx2c4.com/wireguard/tun"
	"golang.zx2c4.com/wireguard/wgctrl"
	"golang.zx2c4.com/wireguard/wgctrl/wgtypes"
)

type wgConn struct {
	// config
	baseName         string
	gatewayCidrBlock *net.IPNet
	vpcCidrBlock     *net.IPNet
	port             string

	// outputs
	gatewayIP string

	// state
	pubKey, privKey wgtypes.Key
	device          *device.Device
	uapi            net.Listener
	errChan         chan error
}

func (w *wgConn) withConfig(cfg auto.ConfigMap) error {

	gCidr, err := parseIPNet(cfg["gateway:cidrBlock"].Value)
	if err != nil {
		return err
	}

	vCidr, err := parseIPNet(cfg["vpc:cidrBlock"].Value)
	if err != nil {
		return err
	}

	w.baseName = cfg["cluster:name"].Value
	w.gatewayCidrBlock = gCidr
	w.port = cfg["gateway:port"].Value
	w.vpcCidrBlock = vCidr

	return nil
}

func parseIPNet(s string) (*net.IPNet, error) {
	_, c, err := net.ParseCIDR(s)
	return c, err
}

func (w *wgConn) withOutputs(outputs map[string]auto.OutputMap) error {
	w.gatewayIP = outputs["gateway"]["gatewayPublicIP"].Value.(string)
	return nil
}

func (w *wgConn) run(ctx *pulumi.Context) error {
	w.errChan = make(chan error)

	// TODO: generate keys and pass around instead of this
	pk, err := wgtypes.ParseKey("eJPl+Xv5i5Y5KfDsiBanTgbYB/F4K1oWqr4PFVWv2kg=")
	if err != nil {
		return err
	}

	pubKey, err := wgtypes.ParseKey("fdjmLLICvyHpMVQMsimEQ0M+ueEN7fyHJv1muuPfskk=")
	if err != nil {
		return err
	}

	w.privKey = pk
	w.pubKey = pubKey

	for _, fn := range []func() error{
		w.createDevice,
		w.createUAPI,
		w.startUAPI,
		w.configureIFace,
		w.start,
	} {
		if err := fn(); err != nil {
			return err
		}
	}
	return nil
}

func (w *wgConn) close() error {
	w.uapi.Close()
	w.device.Close()
	return nil
}

func (w *wgConn) createDevice() error {
	tdev, err := tun.CreateTUN(w.baseName, device.DefaultMTU)
	if err != nil {
		return err
	}

	// TODO(jdt): create device.Logger that wraps logrus
	logger := device.NewLogger(device.LogLevelVerbose, fmt.Sprintf("(%s) ", w.baseName))
	w.device = device.NewDevice(tdev, conn.NewDefaultBind(), logger)

	return nil
}

func (w *wgConn) createUAPI() error {
	fileUAPI, err := ipc.UAPIOpen(w.baseName)
	if err != nil {
		return err
	}

	uapi, err := ipc.UAPIListen(w.baseName, fileUAPI)
	if err != nil {
		return err
	}
	w.uapi = uapi

	return nil
}

func (w *wgConn) startUAPI() error {
	// loop to accept new connections in goroutine
	go func() {
		for {
			c, err := w.uapi.Accept()
			if err != nil {
				w.errChan <- err
			}
			// punt off handling of connection to new goroutine
			go w.device.IpcHandle(c)
		}
	}()

	return nil
}

func (w *wgConn) configureIFace() error {
	c, err := wgctrl.New()
	if err != nil {
		return err
	}

	addr, err := netip.ParseAddrPort(w.gatewayIP + ":" + w.port)
	if err != nil {
		return err
	}

	err = c.ConfigureDevice(w.baseName, wgtypes.Config{
		PrivateKey:   &w.privKey,
		ReplacePeers: true,
		Peers: []wgtypes.PeerConfig{
			{
				PublicKey:         w.pubKey,
				ReplaceAllowedIPs: true,
				AllowedIPs:        []net.IPNet{*w.gatewayCidrBlock, *w.vpcCidrBlock},
				Endpoint:          net.UDPAddrFromAddrPort(addr),
			},
		},
	})
	if err != nil {
		return err
	}

	rtconn, err := rtnl.Dial(nil)
	if err != nil {
		return err
	}

	iface, err := net.InterfaceByName(w.baseName)
	if err != nil {
		return err
	}

	// ip -4 addr add "$ip_w_mask" dev "$dev"
	myIP, err := cidr.Host(w.gatewayCidrBlock, 5)
	if err != nil {
		return err
	}

	if err := rtconn.AddrAdd(iface, &net.IPNet{IP: myIP, Mask: w.gatewayCidrBlock.Mask}); err != nil {
		return err
	}

	// ip link set dev "$dev" up
	if err := rtconn.LinkUp(iface); err != nil {
		return err
	}

	// ip -4 route add "$vpcCidrBlock" dev "$dev"
	gwIP := net.ParseIP("0.0.0.0")
	if err := rtconn.RouteAdd(iface, *w.vpcCidrBlock, gwIP); err != nil {
		return err
	}

	return nil
}

func (w *wgConn) start() error {
	go func() {
		select {
		case err := <-w.errChan:
			fmt.Printf("%v\n", err)
		case <-w.device.Wait():
		}
	}()

	return nil
}
