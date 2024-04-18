package aws

import (
	"io"
	"os"

	"bi/pkg/cluster"
	"bi/pkg/installs"

	"github.com/spf13/cobra"
)

var outputsCmd = &cobra.Command{
	Use:   "outputs [install-slug|install-spec-url|install-spec-file]",
	Short: "Get cluster outputs",
	Long:  `Get outputs for cluster created on AWS EKS.`,
	Args:  cobra.MatchAll(cobra.OnlyValidArgs, cobra.ExactArgs(1)),
	Run: func(cmd *cobra.Command, args []string) {
		// assume output to stdout
		var w io.Writer = os.Stdout

		url := args[0]

		env, err := installs.NewEnv(cmd.Context(), url)
		cobra.CheckErr(err)

		p := cluster.NewPulumiProvider(env.Spec.Slug)

		ctx := cmd.Context()

		err = p.Init(ctx)
		cobra.CheckErr(err)

		err = p.Outputs(ctx, w)
		cobra.CheckErr(err)
	},
}

func init() {
	awsCmd.AddCommand(outputsCmd)
}
