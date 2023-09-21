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
  database: Path.expand("../control_server_int.db", Path.dirname(__ENV__.file)),
  stacktrace: true,
  timeout: 180_000,
  show_sensitive_data_on_connection_error: true

config :home_base, HomeBase.Repo,
  database: Path.expand("../home_base_int.db", Path.dirname(__ENV__.file)),
  stacktrace: true,
  timeout: 180_000,
  show_sensitive_data_on_connection_error: true

config :hackney, use_default_pool: false
