import Config

import_config "test.exs"

config :wallaby,
  screenshot_on_failure: true,
  driver: Wallaby.Chrome,
  hackney_options: [timeout: 5_000]

config :control_server_web, ControlServerWeb.Endpoint,
  http: [port: 4882],
  server: true,
  check_origin: false,
  debug_errors: true

config :home_base_web, HomeBaseWeb.Endpoint,
  http: [port: 4224],
  server: true,
  check_origin: false,
  debug_errors: true

config :kube_ext, cluster_type: :dev

config :kube_services, start_services: true

config :kube_services, KubeServices.SnapshotApply.TimedLauncher,
  delay: 20_000,
  failing_delay: 20_000

config :control_server,
  default_services: [
    :battery,
    :database,
    :istio,
    :istio_istiod
  ]

config :logger, level: :warn

config :control_server, ControlServer.Repo,
  username: System.get_env("POSTGRES_USER") || "batterydbuser",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "server_int_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 300_000,
  timeout: 180_000

config :home_base, HomeBase.Repo,
  username: System.get_env("POSTGRES_USER") || "batterydbuser",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "home_base_int_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 300_000,
  timeout: 180_000
