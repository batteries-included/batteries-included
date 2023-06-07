import Config

# Configure your database
config :control_server, ControlServer.Repo,
  username: System.get_env("POSTGRES_USER") || "batterydbuser",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "control",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false

config :home_base, HomeBase.Repo,
  username: System.get_env("POSTGRES_USER") || "batterydbuser",
  password: System.get_env("POSTGRES_PASSWORD") || "not-real",
  database: System.get_env("POSTGRES_DB") || "home",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: false

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :control_server_web, ControlServerWeb.Endpoint,
  ecto_repos: [ControlServer.Repo],
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {
      Esbuild,
      :install_and_run,
      [:control_server_web, ~w(--sourcemap=inline --watch)]
    },
    npx: [
      "tailwindcss",
      "--postcss",
      "--input=css/app.css",
      "--output=../priv/static/assets/app.css",
      "--watch",
      cd: Path.expand("../apps/control_server_web/assets", __DIR__)
    ],
    npx: [
      "tailwindcss",
      "--postcss",
      "--input=css/storybook.css",
      "--output=../priv/static/assets/storybook.css",
      "--watch",
      cd: Path.expand("../apps/control_server_web/assets", __DIR__)
    ]
  ]

config :home_base_web, HomeBaseWeb.Endpoint,
  http: [port: 4900],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {
      Esbuild,
      :install_and_run,
      [:home_base_web, ~w(--sourcemap=inline --watch)]
    },
    npx: [
      "tailwindcss",
      "--postcss",
      "--input=css/app.css",
      "--output=../priv/static/assets/app.css",
      "--watch",
      cd: Path.expand("../apps/home_base_web/assets", __DIR__)
    ]
  ]

# Watch static and templates for browser reloading.
config :control_server_web, ControlServerWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/control_server_web/(live|views)/.*(ex)$",
      ~r"lib/control_server_web/templates/.*(eex)$",
      ~r"storybook/.*(exs)$"
    ]
  ]

config :home_base_web, HomeBaseWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/home_base_web/(live|views)/.*(ex)$",
      ~r"lib/home_base_web/templates/.*(eex)$"
    ]
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  level: :debug,
  metadata: [:mfa, :request_id],
  handle_otp_reports: true,
  handle_sasl_reports: false

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

config :kube_services, cluster_type: :dev

config :kube_resources, include_dev_infrausers: true

config :control_server, ControlServer.Mailer, adapter: Swoosh.Adapters.Local
