package aws

import (
	"encoding/json"
	"os"
	"time"

	eksutil "bi/pkg/cluster/eks/util"

	"github.com/spf13/cobra"
)

var getTokenCmd = &cobra.Command{
	Use:   "get-token <cluster-name>",
	Short: "Get an auth token for the cluster",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		clusterName := args[0]

		ttl, err := cmd.Flags().GetDuration("ttl")
		cobra.CheckErr(err)

		token, err := eksutil.GetToken(cmd.Context(), clusterName, ttl)
		cobra.CheckErr(err)

		execCredential := map[string]any{
			"kind":       "ExecCredential",
			"apiVersion": "client.authentication.k8s.io/v1beta1",
			"spec":       map[string]any{},
			"status": map[string]any{
				"expirationTimestamp": time.Now().Add(ttl).Format(time.RFC3339),
				"token":               token,
			},
		}

		cobra.CheckErr(json.NewEncoder(os.Stdout).Encode(execCredential))
	},
}

func init() {
	getTokenCmd.Flags().Duration("ttl", 15*time.Minute, "The duration for which the token should be valid")

	awsCmd.AddCommand(getTokenCmd)
}
