import Config

config :common_core, :clusters, default: :service_account

config :kube_bootstrap,
  summary_path: System.fetch_env!("BOOTSTRAP_SUMMARY_PATH")

# We don't need this to update on bootstrap
config :tzdata, :autoupdate, :disabled
