package debug

import (
	"bi/pkg/installs"
	"bi/pkg/log"
	"io"
	"log/slog"
	"os"

	noisysocketsconfig "github.com/noisysockets/noisysockets/config"
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

		conf, err := noisysocketsconfig.FromYAML(wireGuardConfigFile)
		if err != nil {
			return err
		}

		outputPath, err := cmd.Flags().GetString("output")
		if err != nil {
			return err
		}

		slog.Debug("Writing wireguard config", slog.String("outputFilePath", outputPath))

		var w io.Writer
		if outputPath == "-" {
			w = os.Stdout
		} else {
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
	wireGuardConfigCmd.Flags().StringP("output", "o", "-", "Path to write the wireguard config to")

	debugCmd.AddCommand(wireGuardConfigCmd)
}
