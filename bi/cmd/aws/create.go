package aws

import (
	"context"

	"bi/pkg/cluster"

	"github.com/spf13/cobra"
)

var createClusterCmd = &cobra.Command{
	Use:   "createcluster",
	Short: "Create a cluster",
	Long:  `Create a cluster on AWS EKS.`,
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
	awsCmd.AddCommand(createClusterCmd)
}
