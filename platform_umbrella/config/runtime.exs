import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :debug

Logger.put_module_level(K8s.Client.Runner.Stream.Watch, :info)
