import Config

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :control_server_web, ControlServerWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH"),
#         transport_options: [socket_opts: [:inet6]]
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your endpoint, ensuring
# no data is ever sent via http, always redirecting to https:
#
#     config :control_server_web, ControlServerWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

config :common_ui, CommonUIWeb.Endpoint, server: false

config :home_base_web, HomeBaseWeb.Endpoint, url: [host: "www.batteriesincl.com"]

config :kube_services, :clusters, default: :service_account
config :kube_services, cluster_type: :prod

config :logger, :console,
  level: :debug,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  metadata: [:conn, :crash_reason, :request_id],
  compile_time_purge_matching: [
    [library: :k8s]
  ]
