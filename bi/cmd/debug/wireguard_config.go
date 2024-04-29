package debug

import (
	"bi/pkg/installs"
	"bi/pkg/log"
	"bi/pkg/wireguard"
	"log/slog"
	"os"

	"github.com/spf13/cobra"
)

var wireGuardConfigCmd = &cobra.Command{
	Use:   "wireguard-config [install-slug|install-spec-url|install-spec-file]",
	Short: "Get the wireguard config for a batteries included environment",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		url := args[0]

		env, err := installs.NewEnv(cmd.Context(), url)
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		wireGuardConfigFile, err := os.Open(env.WireGuardConfigPath())
		if err != nil {
			return err
		}
		defer wireGuardConfigFile.Close()

		outputFilePath, err := cmd.Flags().GetString("output")
		if err != nil {
			return err
		}

		slog.Debug("Writing wireguard config", slog.String("outputFilePath", outputFilePath))

		outputFile, err := os.OpenFile(outputFilePath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
		if err != nil {
			return err
		}
		defer outputFile.Close()

		if err := wireguard.ToHostConfig(wireGuardConfigFile, outputFile); err != nil {
			return err
		}

		return nil
	},
}

func init() {
	wireGuardConfigCmd.Flags().StringP("output", "o", "wg0.conf", "Path to write the wireguard config to")

	debugCmd.AddCommand(wireGuardConfigCmd)
}
