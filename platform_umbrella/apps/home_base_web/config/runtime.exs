import Config

web_host = System.get_env("WEB_HOST", "anton2")
web_port = System.get_env("WEB_PORT", "8081")
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

config :home_base, HomeBase.Repo,
  ssl: true,
  username: postgres_username,
  password: postgres_password,
  database: postgres_database,
  hostname: postgres_host,
  port: String.to_integer(System.get_env("POSTGRES_PORT") || "5432"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :home_base_web, HomeBaseWeb.Endpoint,
  http: [
    port: String.to_integer(port),
    # url: [host: web_host, port: String.to_integer(web_port)],
    transport_options: [socket_opts: [:inet6]]
  ],
  check_origin: false,
  secret_key_base: secret_key_base,
  server: true

config :common_core, CommonCore.JWK,
  paths: [
    home_a: "/etc/keys/home_a.pem",
    home_b: "/etc/keys/home_b.pem"
  ],
  sign_key: :home_a,
  verify_keys: [:home_a_pub, :home_b_pub]
