/*
Copyright © 2024 Batteries Included <elliott@batteriesincl.com>
*/
package postgres

import (
	"fmt"
	"log/slog"
	"os"
	"os/signal"

	"bi/cmd/cmdutil"
	"bi/pkg/kube"

	"github.com/spf13/cobra"
)

const POSTGRES_PORT = 5432

var portForwardCmd = &cobra.Command{
	Use:   "port-forward postgres-cluster-name",
	Args:  cobra.ExactArgs(1),
	Short: "A brief description of your command",
	Long:  `Port forward to a postgres database on a local kube cluster.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("port forward called")

		clusterName := args[0]
		namespce := cmd.Flag("namespace").Value.String()

		kubeConfigPath, err := cmd.Flags().GetString("kubeconfig")
		cobra.CheckErr(err)

		wireGuardConfigPath, err := cmd.Flags().GetString("wireguard-config")
		cobra.CheckErr(err)

		serviceType, err := cmd.Flags().GetString("service-type")
		cobra.CheckErr(err)

		kubeClient, err := kube.NewBatteryKubeClient(kubeConfigPath, wireGuardConfigPath)
		cobra.CheckErr(err)
		defer kubeClient.Close()

		serviceName := fmt.Sprintf("pg-%s-%s", clusterName, serviceType)

		localPort, err := cmd.Flags().GetInt("local-port")
		cobra.CheckErr(err)

		stopChannel := make(chan struct{}, 1)
		readyChannel := make(chan struct{})

		signals := make(chan os.Signal, 1)
		signal.Notify(signals, os.Interrupt)
		defer signal.Stop(signals)

		forwarder, err := kubeClient.PortForwardService(namespce, serviceName, POSTGRES_PORT, localPort, stopChannel, readyChannel)
		cobra.CheckErr(err)

		go func() {
			<-signals
			if stopChannel != nil {
				slog.Debug("Stopping port forward")
				close(stopChannel)
			}
		}()

		go func() {
			<-readyChannel
			slog.Debug("Port forward ready")
			fmt.Println("Starting proxy...[CTRL-C to exit]")
		}()

		err = forwarder.ForwardPorts()
		cobra.CheckErr(err)
	},
}

func init() {
	postgresCmd.AddCommand(portForwardCmd)
	cmdutil.AddKubeConfigFlag(portForwardCmd)
	cmdutil.AddWireGuardConfigFlag(portForwardCmd)
	portForwardCmd.PersistentFlags().StringP("namespace", "n", "battery-core", "The namespace to use")
	portForwardCmd.Flags().StringP("service-type", "s", "rw", "which service to port forward to (r, rw, ro)")
	portForwardCmd.Flags().IntP("local-port", "l", 5432, "The local port to forward to")
}
