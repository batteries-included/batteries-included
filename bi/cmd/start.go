/*
Copyright © 2024 Elliott Clark <elliott@batteriesincl.com>
*/
package cmd

import (
	"path/filepath"

	"bi/pkg/start"

	"log/slog"

	"github.com/spf13/cobra"
	"k8s.io/client-go/util/homedir"

	"github.com/spf13/viper"
)

// startCmd represents the start command
var startCmd = &cobra.Command{
	Use:   "start [install-spec]",
	Short: "Start a Batteries Included Installation",
	Long: `This will get the configuration for the 
	installation and start the installation process.
	
	If the installation is already started, it will 
	complete the installation and sync all resources 
	that should be created but weren't.
	
	First step is to ensure the kubernetes cluster is started as specified.
	
	The options are:
	
	- Start an EKS cluster
	- Start a local kubernetes cluster using Kind and docker
	- Use an existing kubernetes cluster
	
	Then all the bootstrap resources are created.
	
	Then the cli waits until the installation is 
	complete displaying a url for running control server.`,
	Args: cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		installUrl := args[0]

		kubeConfigPath, err := cmd.Flags().GetString("kubeconfig")
		cobra.CheckErr(err)

		slog.Debug("Starting Batteries Included Installation",
			slog.String("installSpec", installUrl),
			slog.String("kubeconfig", kubeConfigPath))

		err = start.StartInstall(installUrl, kubeConfigPath)
		cobra.CheckErr(err)
	},
}

func init() {
	RootCmd.AddCommand(startCmd)
	// The install spec path as an argument
	// that can be parsed by net/url
	startCmd.Flags().StringP("install-spec", "i", "", "The install spec to use")
	viper.BindPFlag("install-spec", startCmd.Flags().Lookup("install-spec"))

	// The current user homedir
	if dirname := homedir.HomeDir(); dirname == "" {
		startCmd.Flags().StringP("kubeconfig", "k", "/", "The kubeconfig to use")
	} else {
		defaultKubeConfig := filepath.Join(dirname, ".kube", "config")
		startCmd.PersistentFlags().StringP("kubeconfig", "k", defaultKubeConfig, "The kubeconfig to use")
	}
}
