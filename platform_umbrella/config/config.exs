# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

alias CommonUI.Components.Table
alias Tesla.Adapter.Finch

config :common_core, CommonCore.Defaults, version_override: System.get_env("VERSION_OVERRIDE", nil)

config :common_core, CommonCore.JWK,
  sign_key: :test,
  verify_keys: [:test_pub, :home_a_pub, :home_b_pub],
  encrypt_key: :test_pub

config :common_core, CommonCore.Resources.Hashing, key: "/AVk+4bbv7B1Mnh2Rta4U/hvtF7Z3jwFkYny1RqkyiM="

config :common_ui, CommonUIWeb.Endpoint,
  url: [host: "127.0.0.1"],
  adapter: Bandit.PhoenixAdapter,
  secret_key_base: "dpF0Aw3Ikl8AYXURcYog79/++RUd24ocEYlSz1QNXcfVt5itGnOSc572cKW6Fa09",
  pubsub_server: CommonUI.PubSub,
  live_view: [signing_salt: "CGM/Nu66"]

config :control_server, ControlServer.Repo,
  migration_primary_key: [type: :uuid],
  migration_timestamps: [type: :utc_datetime_usec],
  start_apps_before_migration: [:logger_json]

# Configure Mix tasks and generators
config :control_server,
  ecto_repos: [ControlServer.Repo]

# Configures the endpoints
config :control_server_web, ControlServerWeb.Endpoint,
  url: [host: "127.0.0.1"],
  adapter: Bandit.PhoenixAdapter,
  secret_key_base: "+BsWyvsUA0yzXCZIedcDcji/t0CVxE2kofuBpouA44103zsGXTg4w4rSszEXaEfh",
  render_errors: [
    formats: [html: ControlServerWeb.ErrorHTML, json: ControlServerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ControlServer.PubSub,
  live_view: [signing_salt: "IprBitsK"]

config :control_server_web,
  ecto_repos: [ControlServer.Repo],
  generators: [context_app: :control_server, binary_id: true]

config :ex_audit,
  ecto_repos: [ControlServer.Repo],
  version_schema: CommonCore.Audit.EditVersion,
  tracked_schemas: [
    CommonCore.Projects.Project,
    CommonCore.TraditionalServices.Service,
    CommonCore.Batteries.SystemBattery,
    CommonCore.FerretDB.FerretService,
    CommonCore.Knative.Service,
    CommonCore.MetalLB.IPAddressPool,
    CommonCore.Postgres.Cluster,
    CommonCore.Redis.RedisInstance,
    CommonCore.Ollama.ModelInstance
  ],
  primitive_structs: [
    Date,
    DateTime
  ]

config :flop_phoenix,
  pagination: [opts: {Table, :pagination_opts}],
  table: [opts: {Table, :paginated_table_opts}]

config :home_base, HomeBase.Repo,
  migration_primary_key: [type: :uuid],
  migration_timestamps: [type: :utc_datetime_usec],
  start_apps_before_migration: [:logger_json]

config :home_base,
  ecto_repos: [HomeBase.Repo]

config :home_base_web, HomeBaseWeb.Endpoint,
  url: [host: "127.0.0.1"],
  adapter: Bandit.PhoenixAdapter,
  secret_key_base: "7ixRcXBdidan5QEouVvFc1LJ4egRMapcBXaxfmd6EyFJAITgx7PjR/MK4IrkWmrW",
  render_errors: [
    formats: [html: HomeBaseWeb.ErrorHTML, json: HomeBaseWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HomeBase.PubSub,
  live_view: [signing_salt: "zAzBezt3"]

config :home_base_web,
  ecto_repos: [HomeBase.Repo],
  generators: [context_app: :home_base, binary_id: true]

config :kube_services, KubeServices.SnapshotApply.TimedLauncher,
  delay: 900_000,
  failing_delay: 10_000

config :kube_services,
  ecto_repos: [ControlServer.Repo],
  generators: [context_app: :control_server, binary_id: true]

config :kube_services, start_services: true

# Configures Elixir's Logger
config :logger,
  level: :debug,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  compile_time_purge_matching: [
    [library: :k8s]
  ]

config :oauth2,
  debug: false,
  adapter: {Finch, [timeout: 10_500, name: CommonCore.Finch]},
  middleware: [Tesla.Middleware.Telemetry, {Tesla.Middleware.Timeout, timeout: 10_000}]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: CommonCore.Finch

config :tesla, adapter: {Finch, [timeout: 30_000, name: CommonCore.Finch]}

config :verify, :bi_bin_override, System.get_env("BI_BIN_OVERRIDE", nil)

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
