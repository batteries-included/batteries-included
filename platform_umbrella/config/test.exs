import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :kube_usage, KubeUsage.Repo,
  username: "postgres",
  password: "postgres",
  database: "kube_usage_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :kube_usage, KubeUsage.Repo,
  username: System.get_env("POSTGRES_USER") || "batterydbuser",
  password: System.get_env("POSTGRES_PASSWORD") || "notreal",
  database: System.get_env("POSTGRES_DB") || "kube_usage_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

config :control_server, ControlServer.Repo,
  username: System.get_env("POSTGRES_USER") || "batterydbuser",
  password: System.get_env("POSTGRES_PASSWORD") || "notreal",
  database: System.get_env("POSTGRES_DB") || "server_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

config :home_base, HomeBase.Repo,
  username: System.get_env("POSTGRES_USER") || "batterydbuser",
  password: System.get_env("POSTGRES_PASSWORD") || "batterypasswd",
  database: System.get_env("POSTGRES_DB") || "home-base-test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :control_server_web, ControlServerWeb.Endpoint,
  http: [port: 4002],
  server: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :home_base_web, HomeBaseWeb.Endpoint,
  http: [port: 4004],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Don't register bonny controllers so that they aren't started.
# They have to be mocked out way too fucking much.
config :bonny,
  controllers: []
