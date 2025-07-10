package aws

import (
	"encoding/json"
	"log/slog"
	"os"
	"time"

	eksutil "bi/pkg/cluster/eks/util"
	"bi/pkg/installs"
	"bi/pkg/log"

	"github.com/spf13/cobra"
)

var getTokenCmd = &cobra.Command{
	Use:   "get-token [install-slug|install-spec-url|install-spec-file] cluster-name",
	Short: "Get an auth token for the cluster",
	Args:  cobra.ExactArgs(2),
	RunE: func(cmd *cobra.Command, args []string) error {
		installURL := args[0]
		clusterName := args[1]

		ctx := cmd.Context()
		eb := installs.NewEnvBuilder(installs.WithSlugOrURL(installURL))
		env, err := eb.Build(ctx)
		if err != nil {
			return err
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return err
		}

		ttl, err := cmd.Flags().GetDuration("ttl")
		if err != nil {
			return err
		}

		region, err := cmd.Flags().GetString("region")
		if err != nil {
			return err
		}

		slog.Debug("Attempting to get token",
			slog.String("region", region),
			slog.String("clusterName", clusterName),
			slog.Duration("ttl", ttl))

		token, err := eksutil.GetToken(cmd.Context(), region, clusterName, ttl)
		if err != nil {
			return err
		}

		maskedToken := token[:8] + "..." + token[len(token)-8:]
		slog.Debug("Got token", slog.String("token", string(maskedToken)))

		execCredential := map[string]any{
			"kind":       "ExecCredential",
			"apiVersion": "client.authentication.k8s.io/v1beta1",
			"spec":       map[string]any{},
			"status": map[string]any{
				"expirationTimestamp": time.Now().Add(ttl).Format(time.RFC3339),
				"token":               token,
			},
		}

		if err := json.NewEncoder(os.Stdout).Encode(execCredential); err != nil {
			return err
		}

		return nil
	},
}

func init() {
	getTokenCmd.Flags().Duration("ttl", 15*time.Minute, "The duration for which the token should be valid")
	getTokenCmd.Flags().String("region", "", "The AWS region for which the token should be valid")

	awsCmd.AddCommand(getTokenCmd)
}
