package cmd

import (
	"bi/pkg/cluster"
	"context"

	"github.com/spf13/cobra"
)

// createClusterCmd represents the create command
var createClusterCmd = &cobra.Command{
	Use:   "createcluster",
	Short: "Create a cluster",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {
		p := cluster.NewPulumiProvider()
		ctx := context.Background()

		err := p.Init(ctx)
		cobra.CheckErr(err)

		err = p.Create(ctx)
		cobra.CheckErr(err)
	},
}

func init() {
	rootCmd.AddCommand(createClusterCmd)
}
