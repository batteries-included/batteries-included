import Config

web_host = System.get_env("WEB_HOST") || "caxode.com"

config :control_server_web, ControlServerWeb.Endpoint,
  url: [host: web_host, port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"

postgres_username =
  System.get_env("POSTGRES_USER") ||
    raise """
    Need the user env variable POSTGRES_USER
    """

postgres_password =
  System.get_env("POSTGRES_PASSWORD") ||
    raise """
    Need the password env variable POSTGRES_PASSWORD
    """

postgres_database =
  System.get_env("POSTGRES_DB") ||
    raise """
    Need the database name env variable POSTGRES_DB
    """

config :control_server, ControlServer.Repo,
  ssl: true,
  username: postgres_username,
  password: postgres_password,
  database: postgres_database,
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: String.to_integer(System.get_env("POSTGRES_PORT") || "5432"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :home_base, HomeBase.Repo,
  ssl: true,
  username: postgres_username,
  password: postgres_password,
  database: postgres_database,
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: String.to_integer(System.get_env("POSTGRES_PORT") || "5432"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :control_server_web, ControlServerWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

config :home_base_web, HomeBaseWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :control_server_web, ControlServerWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
config :control_server_web, ControlServerWeb.Endpoint, server: true
