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
		// assume output to stdout
		out := os.Stdout

		outArg := args[0]

		// use file for output if requested
		if outArg != "-" {
			f, err := os.OpenFile(outArg, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0o777)
			cobra.CheckErr(err)
			defer f.Close()
			out = f
		}

		p := cluster.NewPulumiProvider()
		ctx := context.Background()

		err := p.Init(ctx)
		cobra.CheckErr(err)

		err = p.Outputs(ctx, out)
		cobra.CheckErr(err)
	},
}

func init() {
	awsCmd.AddCommand(outputsCmd)
}
