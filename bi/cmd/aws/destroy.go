package aws

import (
	"context"

	"bi/pkg/cluster"

	"github.com/spf13/cobra"
)

var destroyClusterCmd = &cobra.Command{
	Use:   "destroycluster",
	Short: "Destroy a cluster",
	Long:  `Destroy a cluster on AWS EKS.`,
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
	awsCmd.AddCommand(destroyClusterCmd)
}
