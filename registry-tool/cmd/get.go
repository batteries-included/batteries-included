/*
Copyright © 2025 Elliott Clark
*/
package cmd

import (
	"encoding/json"
	"fmt"
	"registry-tool/pkg/registry"

	"github.com/spf13/cobra"
)

// getCmd represents the get command
var getCmd = &cobra.Command{
	Use:     "get <file> <key>",
	Example: "registry-tool get registry.yaml my-key",
	Args:    cobra.ExactArgs(2), // Ensure exactly two arguments are provided
	Short:   "Get the registry value for a given key",
	Long:    `Get retrieves the value of a specific key from the registry.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if len(args) != 2 {
			return fmt.Errorf("exactly two arguments required: <file> <key>")
		}

		file := args[0]
		key := args[1]

		reg, err := registry.Read(file)
		if err != nil {
			return fmt.Errorf("failed to read registry file %q: %w", file, err)
		}
		record, found := reg.Get(key)
		if !found {
			return fmt.Errorf("key %q not found in registry file %q", key, file)
		}

		// Print the json representation of the record
		if prettyOutput, err := json.MarshalIndent(record, "", "\t"); err == nil {
			fmt.Println(string(prettyOutput))
		}

		return nil
	},
}

func init() {
	RootCmd.AddCommand(getCmd)
}
