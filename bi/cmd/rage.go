/*
Copyright © 2024 Batteries Included <elliott@batteriesincl.com>
*/
package cmd

import (
	"bi/pkg/installs"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/adrg/xdg"
	"github.com/spf13/cobra"
)

// rageCmd represents the rage command
var rageCmd = &cobra.Command{
	Use:   "rage [install-slug|install-spec-url|install-spec-file]",
	Short: "Collect debug information when things go wrong",
	Args:  cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		installURL := args[0]

		ctx := cmd.Context()
		env, err := installs.NewEnv(ctx, installURL)
		if err != nil {
			return err
		}

		output, err := cmd.Flags().GetString("output")
		if err != nil {
			return err
		}

		var w io.Writer

		switch output {
		case "-":
			w = os.Stdout
		case "":
			logFilename := fmt.Sprintf("%d.json", time.Now().Unix())
			output = filepath.Join(xdg.StateHome, "bi", "rage", logFilename)
			fallthrough

		default:
			output, err = filepath.Abs(output)
			if err != nil {
				return err
			}

			wc, err := setupOutputFile(output)
			if err != nil {
				return err
			}
			defer wc.Close()
			w = wc
		}

		rageReport, err := env.NewRage(ctx)
		if err != nil {
			return err
		}

		err = rageReport.Write(w)
		if err != nil {
			return err
		}

		// print the output file if we're outputting to a file
		if output != "-" {
			fmt.Println(output)
		}

		return nil
	},
}

func setupOutputFile(path string) (io.WriteCloser, error) {
	// Make the rage directory if it doesn't exist
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return nil, fmt.Errorf("unable to create rage directory: %w", err)
	}

	f, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR|os.O_TRUNC, 0644)
	if err != nil {
		return nil, fmt.Errorf("unable to create rage file: %w", err)
	}

	return f, nil
}

func init() {
	rageCmd.Flags().StringP("output", "o", "", "Path to write the rage output to. Use - for stdout.")
	RootCmd.AddCommand(rageCmd)
}
