# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :control_server,
  ecto_repos: [ControlServer.Repo]

# configure paper trail for model history
config :paper_trail,
  repo: ControlServer.Repo,
  item_type: Ecto.UUID,
  originator_type: Ecto.UUID

# Configures the endpoint
config :control_server, ControlServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "s3EZzlHQ8TGyfQYw+LgNkYEHKaKjtmLnc3aQh2+eUyfRa0UuE1Yf44hI1jWk0ii3",
  render_errors: [view: ControlServerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ControlServer.PubSub,
  live_view: [signing_salt: "YG8AIjsI"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :bonny,
  controllers: [
    ControlServer.Controller.V1.BatteryCluster
  ],
  cluster_name: :default,
  # Also configurable via environment variable `BONNY_POD_NAMESPACE`
  namespace: "battery",
  group: "k8s.batteries-included.com",
  operator_name: "battery-control-server",
  service_account_name: "battery-account",
  labels: %{
    "battery-controlled": "true"
  },

  # Operator deployment resources. These are the defaults.
  resources: %{
    limits: %{cpu: "200m", memory: "200Mi"},
    requests: %{cpu: "200m", memory: "200Mi"}
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
