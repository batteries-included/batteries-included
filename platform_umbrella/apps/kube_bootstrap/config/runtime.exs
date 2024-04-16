import Config

config :common_core, :clusters, default: :service_account

# We don't need this to update on bootstrap
config :tzdata, :autoupdate, :disabled
