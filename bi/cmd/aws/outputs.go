package aws

import (
	"context"
	"os"

	"bi/pkg/cluster"

	"github.com/spf13/cobra"
)

var outputsCmd = &cobra.Command{
	Use:   "outputs [file]",
	Short: "Get cluster outputs",
	Long:  `Get outputs for cluster created on AWS EKS.`,
	Args:  cobra.MatchAll(cobra.OnlyValidArgs, cobra.ExactArgs(1)),
	Run: func(cmd *cobra.Command, args []string) {
		f, err := os.OpenFile(args[0], os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0o777)
		cobra.CheckErr(err)
		defer f.Close()

		p := cluster.NewPulumiProvider()
		ctx := context.Background()

		err = p.Init(ctx)
		cobra.CheckErr(err)

		err = p.Outputs(ctx, f)
		cobra.CheckErr(err)
	},
}

func init() {
	awsCmd.AddCommand(outputsCmd)
}
