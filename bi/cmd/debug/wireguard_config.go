package debug

import (
	"bi/pkg/installs"
	"bi/pkg/wireguard"
	"os"

	"github.com/spf13/cobra"
)

var wireGuardConfigCmd = &cobra.Command{
	Use:   "wireguard-config [install-slug|install-spec-url|install-spec-file]",
	Short: "Get the wireguard config for a batteries included environment",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		url := args[0]

		env, err := installs.NewEnv(cmd.Context(), url)
		cobra.CheckErr(err)

		wireGuardConfigFile, err := os.Open(env.WireGuardConfigPath())
		cobra.CheckErr(err)
		defer wireGuardConfigFile.Close()

		outputFilePath, err := cmd.Flags().GetString("output")
		cobra.CheckErr(err)

		outputFile, err := os.OpenFile(outputFilePath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
		cobra.CheckErr(err)
		defer outputFile.Close()

		cobra.CheckErr(wireguard.ToHostConfig(wireGuardConfigFile, outputFile))
	},
}

func init() {
	wireGuardConfigCmd.Flags().StringP("output", "o", "wg0.conf", "Path to write the wireguard config to")

	debugCmd.AddCommand(wireGuardConfigCmd)
}
