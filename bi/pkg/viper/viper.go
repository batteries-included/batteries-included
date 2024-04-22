package viper

import (
	"fmt"
	"log/slog"
	"os"

	"github.com/adrg/xdg"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupConfig(cfgFile string) {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		configDir, err := configPath()
		cobra.CheckErr(err)

		// Search config in config directory with name "bi.yaml"
		viper.AddConfigPath(configDir)
		viper.SetConfigName("bi")
		viper.SetConfigType("yaml")

	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		slog.Debug("Using config file", "file", viper.ConfigFileUsed())
	}
}

func SafeWriteConfig() error {
	configDir, err := configPath()
	if err != nil {
		return fmt.Errorf("unable to get config directory: %w", err)
	}

	if _, err = os.Stat(configDir); !os.IsExist(err) {
		slog.Info("Creating config directory", slog.String("dir", configDir))

		if err := os.MkdirAll(configDir, 0o700); err != nil {
			return fmt.Errorf("unable to create config directory: %w", err)
		}
	}

	return viper.SafeWriteConfig()
}

func configPath() (string, error) {
	return xdg.ConfigFile("bi")
}
