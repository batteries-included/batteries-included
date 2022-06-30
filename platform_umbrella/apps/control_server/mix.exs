defmodule ControlServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :control_server,
      version: "0.3.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {ControlServer.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Auth
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.0"},
      {:oban, "~> 2.12"},
      {:phoenix_swoosh, "~> 1.0"},
      {:phoenix_swoosh, "~> 1.0"},

      # SQL
      {:phoenix_ecto, "~> 4.4"},
      {:typed_ecto_schema, "~> 0.4.1"},
      {:ecto_sql, "~> 3.8"},
      {:postgrex, ">= 0.0.0"},

      # Filtering
      {:paginator, "~> 1.1.0"},

      # Kubernetes
      {:telemetry, "~> 1.0", override: true},
      {:k8s, "~> 1.1"},
      {:httpoison, "~> 1.4"},
      {:poison, "~> 5.0"},
      {:kube_ext, in_umbrella: true},
      {:kube_raw_resources, in_umbrella: true},

      # Yaml
      {:yaml_elixir, "~> 2.6"},

      # Time
      {:timex, "~> 3.7"},

      # Naming
      {:mnemonic_slugs, "~> 0.0.3"},
      {:event_center, in_umbrella: true},

      ## Dev/Test only deps

      # Testing.
      {:ex_machina, "~> 2.7", only: :test},
      {:floki, "~> 0.33", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],

      # We want to be able to test seeding the data so mix ecto.reset no
      # longer seeds the database. This allows tests to
      # MIX_ENV=test mix ecto.reset && mix test
      "ecto.reset": ["ecto.drop", "ecto.create", "ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
