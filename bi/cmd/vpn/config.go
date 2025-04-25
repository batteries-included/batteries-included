package vpn

import (
	"bi/pkg/installs"
	"bi/pkg/log"
	"log/slog"
	"os"

	noisysocketsconfig "github.com/noisysockets/noisysockets/config"
	"github.com/spf13/cobra"
)

var vpnConfigCmd = &cobra.Command{
	Use:   "config [install-slug|install-spec-url|install-spec-file]",
	Short: "Get the wireguard config for a batteries included environment",
	Args:  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
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

		conf, err := noisysocketsconfig.FromYAML(wireGuardConfigFile)
		if err != nil {
			return err
		}

		outputPath, err := cmd.Flags().GetString("output")
		if err != nil {
			return err
		}

		slog.Info("Writing wireguard config", slog.String("outputFilePath", outputPath))

		w := os.Stdout
		if outputPath != "-" {
			outputFile, err := os.OpenFile(outputPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
			if err != nil {
				return err
			}
			defer outputFile.Close()

			w = outputFile
		}

		if err := noisysocketsconfig.ToINI(w, conf); err != nil {
			return err
		}

		return nil
	},
}

func init() {
	vpnConfigCmd.Flags().StringP("output", "o", "-", "Path to write the wireguard config to")

	vpnCmd.AddCommand(vpnConfigCmd)
}
