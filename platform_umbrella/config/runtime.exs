import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :debug

if config_env() == :prod do
  config :logger, :default_handler, formatter: LoggerJSON.Formatters.Basic.new(metadata: [:mfa, :request_id])
end
