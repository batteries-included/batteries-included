import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#

# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :control_server, ControlServer.Repo,
  username: System.get_env("POSTGRES_USER") || "batterydbuser",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "server_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

config :home_base, HomeBase.Repo,
  username: System.get_env("POSTGRES_USER") || "batterydbuser",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "home-base-test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
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

config :kube_ext, cluster_type: :dev

config :kube_services, start_services: false

config :kube_services, Oban, testing: :inline, plugins: []
