package aws

import (
	"io"
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
		var w io.Writer = os.Stdout

		outArg := args[0]

		// use file for output if requested
		if outArg != "-" {
			f, err := os.OpenFile(outArg, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0o777)
			cobra.CheckErr(err)
			defer f.Close()
			w = f
		}

		p := cluster.NewPulumiProvider()

		ctx := cmd.Context()

		err := p.Init(ctx)
		cobra.CheckErr(err)

		err = p.Outputs(ctx, w)
		cobra.CheckErr(err)
	},
}

func init() {
	awsCmd.AddCommand(outputsCmd)
}
