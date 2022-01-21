import Config

# postgres_username =
#   System.get_env("POSTGRES_USER") ||
#     raise """
#     Need the user env variable POSTGRES_USER
#     """

# postgres_password =
#   System.get_env("POSTGRES_PASSWORD") ||
#     raise """
#     Need the password env variable POSTGRES_PASSWORD
#     """

# postgres_host =
#   System.get_env("POSTGRES_HOST") ||
#     raise """
#     Need the database host in env variable POSTGRES_HOST
#     """

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :debug,
  metadata: [:mfa, :request_id]
