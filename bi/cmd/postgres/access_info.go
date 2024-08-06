package postgres

import (
	"bi/pkg/installs"
	"bi/pkg/log"
	"fmt"
	"net/url"

	"github.com/spf13/cobra"
)

var accessInfoCmd = &cobra.Command{
	Use:   "access-info [install-slug|install-spec-url|install-spec-file] postgres-cluster-name user-name",
	Short: "Print the information to access a Postgres database",
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

		dsn := postgresAccessSpec.DSN
		u, err := url.Parse(dsn)
		if err != nil {
			return fmt.Errorf("failed to parse DSN: %v", err)
		}

		if cmd.Flag("localhost").Value.String() == "true" {
			u.Host = "localhost"
			q := u.Query()
			q.Set("sslmode", "allow")
			u.RawQuery = q.Encode()
		}

		fmt.Println(u)

		return nil
	},
}

func init() {
	postgresCmd.AddCommand(accessInfoCmd)
	accessInfoCmd.PersistentFlags().StringP("namespace", "n", "battery-core", "The namespace to use")
	accessInfoCmd.PersistentFlags().BoolP("localhost", "l", false, "Use localhost instead of the hostname name")
}
