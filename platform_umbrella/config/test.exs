import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#

# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :control_server, ControlServer.Repo,
  username: System.get_env("POSTGRES_USER") || "battery-local-user",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "control-server-test",
  hostname: System.get_env("POSTGRES_HOST") || "127.0.0.1",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

config :home_base, HomeBase.Repo,
  username: System.get_env("POSTGRES_USER") || "battery-local-user",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "home-base-test",
  hostname: System.get_env("POSTGRES_HOST") || "127.0.0.1",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

# Configures the endpoints
config :common_ui, CommonUIWeb.Endpoint,
  http: [port: 4001],
  server: false

config :control_server_web, ControlServerWeb.Endpoint,
  http: [port: 4002],
  server: false

config :home_base_web, HomeBaseWeb.Endpoint,
  http: [port: 4003],
  server: false

# Print only warnings and errors during test
config :logger, level: :error

config :kube_services, start_services: false, cluster_type: :dev

config :home_base, HomeBase.Mailer, adapter: Swoosh.Adapters.Test

config :wallaby,
  screenshot_on_failure: true,
  driver: Wallaby.Chrome,
  max_wait_time: 60_000,
  hackney_options: [timeout: :infinity, recv_timeout: :infinity]
