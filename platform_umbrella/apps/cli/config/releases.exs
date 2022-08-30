import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :debug,
  metadata: [:mfa]

config :cli, should_halt: true

config :kube_ext, cluster_type: :dev
