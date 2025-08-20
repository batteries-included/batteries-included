package viper

import (
	"fmt"
	"log/slog"
	"os"
	"strings"

	"github.com/adrg/xdg"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupConfig(cfgFile string) error {
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

	// Setup environment variable prefix
	viper.SetEnvPrefix("BI")
	viper.AutomaticEnv() // read in environment variables that match

	// Allow reading from environment variables with different key formats
	viper.SetEnvKeyReplacer(strings.NewReplacer("-", "_"))

	// Bind environment variables explicitly for better control
	viper.BindEnv("allow-test-keys", "BI_ALLOW_TEST_KEYS")
	viper.BindEnv("nvidia-auto-discovery", "BI_NVIDIA_AUTO_DISCOVERY")

	// Set defaults
	viper.SetDefault("allow-test-keys", false)
	viper.SetDefault("nvidia-auto-discovery", true)

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		slog.Debug("Using config file", "file", viper.ConfigFileUsed())
	}

	return nil
}

// BindFlags binds command flags to viper configuration
func BindFlags(cmd *cobra.Command) error {
	return viper.BindPFlags(cmd.Flags())
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
