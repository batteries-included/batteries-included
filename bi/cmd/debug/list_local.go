package debug

import (
	"bi/pkg/installs"
	"fmt"

	"github.com/spf13/cobra"
)

var listLocalCmd = &cobra.Command{
	Use:   "list-local",
	Short: "List all possible installations on the local machine",
	Args:  cobra.NoArgs,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx := cmd.Context()

		return installs.ListInstallations(ctx, func(install *installs.InstallEnv) error {
			// print tab separated values
			// slug, path, provider
			fmt.Printf("%s\t%s\t%s\n", install.Slug, install.InstallStateHome(), install.Spec.KubeCluster.Provider)
			return nil
		})
	},
}

func init() {
	debugCmd.AddCommand(listLocalCmd)
}
