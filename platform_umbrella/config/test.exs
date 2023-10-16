import Config

# Configure your database
#

# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :control_server, ControlServer.Repo,
  username: System.get_env("POSTGRES_USER") || "battery-local-user",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "server_test",
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

config :control_server_web, ControlServerWeb.Endpoint,
  http: [port: 4002],
  server: false

config :home_base_web, HomeBaseWeb.Endpoint,
  http: [port: 4004],
  server: false

# Print only warnings and errors during test
config :logger, level: :error

config :kube_services, start_services: false, cluster_type: :dev
