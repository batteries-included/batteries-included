import Config

import_config "test.exs"

config :wallaby,
  screenshot_on_failure: true,
  driver: Wallaby.Chrome,
  hackney_options: [timeout: 5_000],
  chromedriver: [
    binary: System.get_env("WALLABY_CHROME_BINARY")
  ]

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

config :kube_services,
  cluster_type: :dev,
  start_services: true

config :kube_services, KubeServices.SnapshotApply.TimedLauncher,
  delay: 20_000,
  failing_delay: 20_000

config :logger, level: :warning

config :control_server, ControlServer.Repo,
  username: System.get_env("POSTGRES_USER") || "battery-local-user",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "server-int-test",
  hostname: System.get_env("POSTGRES_HOST") || "127.0.0.1",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true

config :home_base, HomeBase.Repo,
  username: System.get_env("POSTGRES_USER") || "battery-local-user",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "home-base-int-test",
  hostname: System.get_env("POSTGRES_HOST") || "127.0.0.1",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true

config :hackney, use_default_pool: false
