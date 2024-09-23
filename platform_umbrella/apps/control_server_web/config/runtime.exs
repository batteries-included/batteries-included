import Config

port = System.get_env("PORT", "4000")

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

postgres_host =
  System.get_env("POSTGRES_HOST") ||
    raise """
    Need the database host in env variable POSTGRES_HOST
    """

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :common_core, CommonCore.JWK,
  sign_key: nil,
  verify_keys: [:home_a_pub, :home_b_pub]

config :common_core, :clusters, default: :service_account

config :control_server, ControlServer.Repo,
  database: postgres_database,
  hostname: postgres_host,
  log: false,
  password: postgres_password,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  port: String.to_integer(System.get_env("POSTGRES_PORT") || "5432"),
  ssl: true,
  ssl_opts: [verify: :verify_none],
  username: postgres_username

config :control_server_web, ControlServerWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [port: String.to_integer(port)],
  check_origin: false,
  secret_key_base: secret_key_base,
  server: true

config :kube_services, cluster_type: :prod
