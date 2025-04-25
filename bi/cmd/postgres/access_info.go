package postgres

import (
	"bi/pkg/installs"
	"bi/pkg/log"
	"encoding/json"
	"fmt"
	"net/url"

	"github.com/spf13/cobra"
)

var accessInfoCmd = &cobra.Command{
	Use:   "access-info [install-slug|install-spec-url|install-spec-file] postgres-cluster-name user-name",
	Short: "Print the information to access a Postgres database",
	Args:  cobra.MatchAll(cobra.ExactArgs(3), cobra.OnlyValidArgs),
	RunE: func(cmd *cobra.Command, args []string) error {
		installUrl := args[0]

		env, err := installs.NewEnv(cmd.Context(), installUrl)
		if err != nil {
			return fmt.Errorf("failed to create environment: %v", err)
		}

		if err := log.CollectDebugLogs(env.DebugLogPath(cmd.CommandPath())); err != nil {
			return fmt.Errorf("failed to collect debug logs: %v", err)
		}

		kubeClient, err := env.NewBatteryKubeClient()
		if err != nil {
			return fmt.Errorf("failed to create kube client: %v", err)
		}
		defer kubeClient.Close()

		postgresClusterName := args[1]
		userName := args[2]
		namespace := cmd.Flag("namespace").Value.String()

		postgresAccessSpec, err := kubeClient.GetPostgresAccessInfo(cmd.Context(), namespace, postgresClusterName, userName)
		if err != nil {
			return fmt.Errorf("failed to get postgres access info: %v", err)
		}

		// If the user is trying to connect to a database they likely
		// are portforwarding to a database that's in a kube cluster
		//
		// Change the hostname to localhost and set sslmode to allow
		// so that the user can connect to the database
		if cmd.Flag("localhost").Value.String() == "true" {
			dsn := postgresAccessSpec.DSN
			u, err := url.Parse(dsn)
			if err != nil {
				return fmt.Errorf("failed to parse DSN: %v", err)
			}
			u.Host = "localhost"
			q := u.Query()
			q.Set("sslmode", "allow")
			u.RawQuery = q.Encode()

			// Change the access spec to reflect the changes
			postgresAccessSpec.Hostname = "localhost"
			postgresAccessSpec.DSN = u.String()
		}

		output := postgresAccessSpec.DSN

		if cmd.Flag("json").Value.String() == "true" {
			value, err := json.Marshal(postgresAccessSpec)
			if err != nil {
				return fmt.Errorf("failed to marshal postgres access spec: %v", err)
			}
			output = string(value)
		}

		fmt.Println(output)
		return nil
	},
}

func init() {
	postgresCmd.AddCommand(accessInfoCmd)
	accessInfoCmd.PersistentFlags().StringP("namespace", "n", "battery-core", "The namespace to use")
	accessInfoCmd.PersistentFlags().BoolP("localhost", "l", false, "Use localhost instead of the hostname name")
	accessInfoCmd.PersistentFlags().BoolP("json", "j", false, "Output in JSON format")
}
