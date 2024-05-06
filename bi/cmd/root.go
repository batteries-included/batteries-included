/*
Copyright © 2024 Elliott Clark
*/
package cmd

import (
	"log/slog"
	"os"

	"bi/pkg/log"
	biviper "bi/pkg/viper"

	"github.com/gregwebs/go-recovery"
	"github.com/spf13/cobra"
)

var cfgFile string
var verbosity string
var color bool

// rootCmd represents the base command when called without any subcommands
var RootCmd = &cobra.Command{
	Use:   "bi",
	Short: "A CLI for Batteries Included infrastructure",
	Long: `An all in one cli for installing and
debugging Batteries Included infrastructure
on top of kubernetes`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		return log.SetupLogging(verbosity, color)
	},
	// We do our own error logging.
	SilenceErrors:      true,
	DisableSuggestions: true,
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	if err := recovery.Call(RootCmd.Execute); err != nil {
		slog.Error("Error executing command", slog.Any("error", err))
		os.Exit(1)
	}
}

func init() {
	cobra.OnInitialize(initConfig)
	RootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $XDG_CONFIG_HOME/bi/bi.yaml)")
	RootCmd.PersistentFlags().StringVarP(&verbosity, "verbosity", "v", slog.LevelWarn.String(), "Log level (debug, info, warn, error")
	RootCmd.PersistentFlags().BoolVarP(&color, "color", "c", true, "Use color in logs")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	biviper.SetupConfig(cfgFile)
}
