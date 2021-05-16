defmodule ControlServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :control_server,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
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
      {:phoenix_pubsub, "~> 2.0"},
      {:jason, "~> 1.0"},

      # SQL
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},

      # Filtering
      {:filtrex, "~> 0.4.3"},

      # Kubernetes
      {:bonny, "~> 0.4"},
      {:httpoison, "~> 1.4"},
      {:poison, "~> 4.0"},

      # Yaml
      {:yaml_elixir, "~> 2.6"},

      # Time
      {:timex, "~> 3.7"},
      {:home_base_client, in_umbrella: true},

      ## Dev/Test only deps

      # Auth
      {:phx_gen_auth, "~> 0.7", only: [:dev], runtime: false},

      # Dev reload for phoenix
      {:phoenix_live_reload, "~> 1.3", only: :dev},

      # Testing.
      {:ex_machina, "~> 2.7", only: :test},
      {:floki, "~> 0.30", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
