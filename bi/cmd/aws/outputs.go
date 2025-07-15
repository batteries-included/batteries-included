package aws

import (
	"io"
	"os"

	"bi/pkg/cluster"
	"bi/pkg/installs"
	"bi/pkg/log"

	"github.com/spf13/cobra"
)

var outputsCmd = &cobra.Command{
	Use:   "outputs [install-slug|install-spec-url|install-spec-file]",
	Short: "Get cluster outputs",
	Long:  `Get outputs for cluster created on AWS EKS.`,
	Args:  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		// assume output to stdout
		var w io.Writer = os.Stdout

		installURL := args[0]

		ctx := cmd.Context()

		eb := installs.NewEnvBuilder(installs.WithSlugOrURL(installURL))
		env, err := eb.Build(ctx)
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		p := cluster.NewPulumiProvider(env.Spec)

		if err := p.Init(ctx); err != nil {
			return err
		}

		if err := p.WriteOutputs(ctx, w); err != nil {
			return err
		}

		return nil
	},
}

func init() {
	awsCmd.AddCommand(outputsCmd)
}
