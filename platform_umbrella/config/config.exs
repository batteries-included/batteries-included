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

# Configure Mix tasks and generators
config :control_server,
  ecto_repos: [ControlServer.Repo]

config :control_server, ControlServer.Repo,
  migration_primary_key: [type: :uuid],
  migration_timestamps: [type: :utc_datetime_usec]

config :home_base,
  ecto_repos: [HomeBase.Repo]

config :home_base, HomeBase.Repo,
  migration_primary_key: [type: :uuid],
  migration_timestamps: [type: :utc_datetime_usec]

config :control_server_web,
  ecto_repos: [ControlServer.Repo],
  generators: [context_app: :control_server, binary_id: true]

config :home_base_web,
  ecto_repos: [HomeBase.Repo],
  generators: [context_app: :home_base, binary_id: true]

config :kube_services,
  ecto_repos: [ControlServer.Repo],
  generators: [context_app: :control_server, binary_id: true]

config :ex_audit,
  ecto_repos: [ControlServer.Repo],
  version_schema: CommonCore.Audit.EditVersion,
  tracked_schemas: [
    CommonCore.Batteries.SystemBattery,
    CommonCore.Knative.Service,
    CommonCore.MetalLB.IPAddressPool,
    CommonCore.Postgres.Cluster,
    CommonCore.Redis.FailoverCluster
  ]

# Configures the endpoint
config :control_server_web, ControlServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "+BsWyvsUA0yzXCZIedcDcji/t0CVxE2kofuBpouA44103zsGXTg4w4rSszEXaEfh",
  render_errors: [
    formats: [html: ControlServerWeb.ErrorHTML, json: ControlServerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: ControlServer.PubSub,
  live_view: [signing_salt: "IprBitsK"]

# Configures the endpoint
config :home_base_web, HomeBaseWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "7ixRcXBdidan5QEouVvFc1LJ4egRMapcBXaxfmd6EyFJAITgx7PjR/MK4IrkWmrW",
  render_errors: [
    formats: [html: HomeBaseWeb.ErrorHTML, json: HomeBaseWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: HomeBase.PubSub,
  live_view: [signing_salt: "zAzBezt3"]

# Configures Elixir's Logger
config :logger,
  level: :debug,
  handle_otp_reports: true,
  handle_sasl_reports: false

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.17.19",
  control_server_web: [
    args:
      ~w(js/app.js js/storybook.js --bundle --target=chrome109,firefox112,safari15.6,edge112 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --loader:.woff2=file --loader:.woff=file),
    cd: Path.expand("../apps/control_server_web/assets", __DIR__)
  ],
  home_base_web: [
    args:
      ~w(js/app.js --bundle --target=chrome109,firefox112,safari15.6,edge112 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --loader:.woff2=file --loader:.woff=file),
    cd: Path.expand("../apps/home_base_web/assets", __DIR__)
  ]

config :kube_services, start_services: true

config :kube_services, KubeServices.SnapshotApply.TimedLauncher,
  delay: 900_000,
  failing_delay: 10_000

config :kube_services, Oban,
  repo: ControlServer.Repo,
  queues: [default: 10, kube: 10],
  plugins: [
    Oban.Plugins.Stager,
    Oban.Plugins.Reindexer,
    {Oban.Plugins.Pruner, max_age: 3600},
    {Oban.Plugins.Cron,
     crontab: [
       {"*/11 * * * *", KubeServices.Stale.InitialWorker}
     ]}
  ]

config :control_server, ControlServer.Mailer, adapter: Swoosh.Adapters.Local

config :common_core, CommonCore.Resources.Hashing,
  key: "/AVk+4bbv7B1Mnh2Rta4U/hvtF7Z3jwFkYny1RqkyiM="

config :tesla, adapter: {Tesla.Adapter.Mint, [timeout: 30_000]}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
