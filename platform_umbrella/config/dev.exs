import Config

config :common_core, :clusters, default: {:file, System.get_env("KUBE_CONFIG_FILE") || "~/.kube/config"}

config :common_ui, CommonUIWeb.Endpoint,
  http: [port: 4200],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    npm: ["run", "css:storybook", "--", "--watch", cd: Path.expand("../apps/common_ui/assets", __DIR__)],
    npm: ["run", "js:storybook", "--", "--watch", cd: Path.expand("../apps/common_ui/assets", __DIR__)]
  ]

config :common_ui, CommonUIWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/common_ui_web/(components|live)/.*(ex|heex)$",
      ~r"storybook/.*(exs)$"
    ]
  ]

# Configure your database
config :control_server, ControlServer.Repo,
  username: System.get_env("POSTGRES_USER") || "battery-local-user",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "control",
  hostname: System.get_env("POSTGRES_HOST") || "127.0.0.1",
  # For development, we disable any cache and enable
  # debugging and code reloading.
  #
  # The watchers configuration can be used to run external
  # watchers to your application. For example, we use it
  # with webpack to recompile .js and .css sources.
  port: System.get_env("POSTGRES_PORT") || 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false

config :control_server_web, ControlServerWeb.Endpoint,
  ecto_repos: [ControlServer.Repo],
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    npm: ["run", "css:deploy:dev", "--", "--watch", cd: Path.expand("../apps/control_server_web/assets", __DIR__)],
    npm: ["run", "js:deploy:dev", "--", "--watch", cd: Path.expand("../apps/control_server_web/assets", __DIR__)]
  ]

# Watch static and templates for browser reloading.
config :control_server_web, ControlServerWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/gettext/.*(po)$",
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/control_server_web/(components|controllers|live)/.*(ex|heex)$"
    ]
  ]

config :home_base, HomeBase.Mailer, adapter: Swoosh.Adapters.Local

config :home_base, HomeBase.Repo,
  username: System.get_env("POSTGRES_USER") || "battery-local-user",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "home",
  hostname: System.get_env("POSTGRES_HOST") || "127.0.0.1",
  port: System.get_env("POSTGRES_PORT") || 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false

config :home_base_web, HomeBaseWeb.Endpoint,
  http: [port: 4100],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    npm: ["run", "css:deploy:dev", "--", "--watch", cd: Path.expand("../apps/home_base_web/assets", __DIR__)],
    npm: ["run", "js:deploy:dev", "--", "--watch", cd: Path.expand("../apps/home_base_web/assets", __DIR__)]
  ]

config :home_base_web, HomeBaseWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/gettext/.*(po)$",
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/home_base_web/(components|controllers|live)/.*(ex|heex)$"
    ]
  ]

config :kube_services, cluster_type: :dev

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :debug,
  metadata:
    ~w(mfa request_id name namespace fail_cnt cluster retries_left type reason error errors realm action kind result pid id status pool)a,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  compile_time_purge_matching: [
    [library: :k8s]
  ]

# Initialize plugs at runtime for faster development compilation
# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :plug_init_mode, :runtime
config :phoenix, :stacktrace_depth, 20

# Include HEEx debug annotations as HTML comments in rendered markup
config :phoenix_live_view, :debug_heex_annotations, true
