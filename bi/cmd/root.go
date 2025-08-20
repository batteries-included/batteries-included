/*
Copyright © 2024 Elliott Clark
*/
package cmd

import (
	"log/slog"
	"os"

	"bi/pkg"
	"bi/pkg/log"
	biviper "bi/pkg/viper"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// rootCmd represents the base command when called without any subcommands
var RootCmd = &cobra.Command{
	Use:     "bi",
	Version: pkg.Version,
	Short:   "A CLI for Batteries Included infrastructure",
	Long: `An all in one cli for installing and
debugging Batteries Included infrastructure
on top of kubernetes`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		// Initialize Viper configuration first
		if err := biviper.SetupConfig(viper.GetString("config")); err != nil {
			return err
		}

		// Then setup logging using Viper values
		verbosity := viper.GetString("verbosity")
		color := viper.GetBool("color")
		return log.SetupLogging(verbosity, color)
	},
	// We do our own error logging.
	SilenceErrors:      true,
	DisableSuggestions: true,
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := RootCmd.Execute(); err != nil {
		slog.Error("Error executing command", slog.Any("error", err))
		os.Exit(1)
	}
}

func init() {
	// Define persistent flags
	RootCmd.PersistentFlags().String("config", "", "config file (default is $XDG_CONFIG_HOME/bi/bi.yaml)")
	RootCmd.PersistentFlags().StringP("verbosity", "v", slog.LevelWarn.String(), "Log level (debug, info, warn, error)")
	RootCmd.PersistentFlags().BoolP("color", "c", true, "Use color in logs")

	// Bind flags to Viper
	viper.BindPFlag("config", RootCmd.PersistentFlags().Lookup("config"))
	viper.BindPFlag("verbosity", RootCmd.PersistentFlags().Lookup("verbosity"))
	viper.BindPFlag("color", RootCmd.PersistentFlags().Lookup("color"))
}
