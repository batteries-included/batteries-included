package debug

import (
	"fmt"

	"bi/pkg/installs"
	"bi/pkg/log"

	"github.com/spf13/cobra"
)

var kubeConfigPath = &cobra.Command{
	Use:   "kube-config-path [install-slug|install-spec-url|install-spec-file]",
	Short: "Print the path to the install's kube config",
	Args:  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		env, err := installs.NewEnv(cmd.Context(), args[0])
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		fmt.Print(env.KubeConfigPath())

		return nil
	},
}

func init() {
	debugCmd.AddCommand(kubeConfigPath)
}
