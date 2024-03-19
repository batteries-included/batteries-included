package cmdutil

import (
	"log/slog"
	"path/filepath"

	"github.com/spf13/cobra"
	"k8s.io/client-go/util/homedir"
)

func AddKubeConfigFlag(cmd *cobra.Command) {
	dirname := homedir.HomeDir()
	if dirname == "" {
		slog.Debug("No home directory found for kubeconfig ")
		cmd.PersistentFlags().StringP("kubeconfig", "k", "/", "The kubeconfig to use")

		return
	}

	defaultKubeConfig := filepath.Join(dirname, ".kube", "config")
	cmd.PersistentFlags().StringP("kubeconfig", "k", defaultKubeConfig, "The kubeconfig to use")
}
