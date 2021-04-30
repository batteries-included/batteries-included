# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config

# Configure Mix tasks and generators
config :control_server,
  ecto_repos: [ControlServer.Repo]

config :control_server, ControlServer.Repo, migration_primary_key: [type: :uuid]

config :control_server_web,
  ecto_repos: [ControlServer.Repo],
  generators: [context_app: :control_server, binary_id: true]

# Configures the endpoint
config :control_server_web, ControlServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+BsWyvsUA0yzXCZIedcDcji/t0CVxE2kofuBpouA44103zsGXTg4w4rSszEXaEfh",
  render_errors: [view: ControlServerWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ControlServer.PubSub,
  live_view: [signing_salt: "IprBitsK"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

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
