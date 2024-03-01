package cmd

import (
	"bi/pkg/cluster"
	"context"

	"github.com/spf13/cobra"
)

// destroyClusterCmd represents the destroy command
var destroyClusterCmd = &cobra.Command{
	Use:   "destroycluster",
	Short: "A brief description of your command",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {
		p := cluster.NewPulumiProvider()
		ctx := context.Background()

		err := p.Init(ctx)
		cobra.CheckErr(err)

		err = p.Destroy(ctx)
		cobra.CheckErr(err)
	},
}

func init() {
	rootCmd.AddCommand(destroyClusterCmd)
}
