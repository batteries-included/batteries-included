/*
Copyright © 2024 Batteries Included <elliott@batteriesincl.com>
*/
package postgres

import (
	"fmt"
	"log/slog"
	"os"
	"os/signal"

	"bi/pkg/installs"

	"github.com/spf13/cobra"
)

const POSTGRES_PORT = 5432

var portForwardCmd = &cobra.Command{
	Use:   "port-forward [install-slug|install-spec-url|install-spec-file] postgres-cluster-name",
	Args:  cobra.ExactArgs(2),
	Short: "A brief description of your command",
	Long:  `Port forward to a postgres database on a local kube cluster.`,
	Run: func(cmd *cobra.Command, args []string) {
		url := args[0]

		env, err := installs.NewEnv(cmd.Context(), url)
		cobra.CheckErr(err)

		fmt.Println("port forward called")

		postgresClusterName := args[1]
		namespce := cmd.Flag("namespace").Value.String()

		serviceType, err := cmd.Flags().GetString("service-type")
		cobra.CheckErr(err)

		kubeClient, err := env.NewBatteryKubeClient()
		cobra.CheckErr(err)
		defer kubeClient.Close()

		serviceName := fmt.Sprintf("pg-%s-%s", postgresClusterName, serviceType)

		localPort, err := cmd.Flags().GetInt("local-port")
		cobra.CheckErr(err)

		stopChannel := make(chan struct{}, 1)
		readyChannel := make(chan struct{})

		signals := make(chan os.Signal, 1)
		signal.Notify(signals, os.Interrupt)
		defer signal.Stop(signals)

		forwarder, err := kubeClient.PortForwardService(cmd.Context(), namespce, serviceName, POSTGRES_PORT, localPort, stopChannel, readyChannel)
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
	portForwardCmd.PersistentFlags().StringP("namespace", "n", "battery-core", "The namespace to use")
	portForwardCmd.Flags().StringP("service-type", "s", "rw", "which service to port forward to (r, rw, ro)")
	portForwardCmd.Flags().IntP("local-port", "l", 5432, "The local port to forward to")
}
