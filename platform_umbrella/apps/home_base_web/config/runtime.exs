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
  primary_home_base_key: :environment,
  verify_keys: [:home_a_pub, :home_b_pub]

config :home_base, HomeBase.Mailer,
  adapter: Swoosh.Adapters.Postmark,
  # Fall back to the black hole postmark server if no key is provided
  api_key: System.get_env("POSTMARK_KEY") || "d382f183-4b4b-417f-82db-3f9635a05c8b"

config :home_base, HomeBase.Repo,
  database: postgres_database,
  hostname: postgres_host,
  log: false,
  password: postgres_password,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  port: String.to_integer(System.get_env("POSTGRES_PORT") || "5432"),
  ssl: true,
  ssl_opts: [verify: :verify_none],
  username: postgres_username

config :home_base_web, HomeBaseWeb.Endpoint,
  http: [port: String.to_integer(port)],
  check_origin: false,
  secret_key_base: secret_key_base,
  server: true
