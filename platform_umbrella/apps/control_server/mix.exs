defmodule ControlServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :control_server,
      version: "0.10.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: test_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {ControlServer.Application, []},
      extra_applications: [:logger, :runtime_tools, :dialyzer]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:event_center, in_umbrella: true},
      {:common_core, in_umbrella: true},
      {:phoenix_pubsub, "~> 2.1"},
      {:jason, "~> 1.4.1"},
      {:phoenix, "~> 1.7.7"},
      {:phoenix_swoosh, "~> 1.2.0"},

      # SQL
      {:phoenix_ecto, "~> 4.4.2"},
      {:typed_ecto_schema, "~> 0.4.1"},
      {:polymorphic_embed, "~> 3.0.5"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.17.2"},
      {:ecto_sqlite3, "~> 0.11.0", only: [:test, :integration]},

      # Filtering
      {:flop, "~> 0.23.0"},

      # History
      {:ex_audit, "~> 0.10.0"},

      # Kubernetes
      {:k8s, "~> 2.4.1"},

      # Yaml
      {:ymlr, "~> 4.2.0"},
      {:yaml_elixir, "~> 2.6"},

      # Time
      {:timex, "~> 3.7"},

      ## Dev/Test only deps

      # Testing.
      {:ex_machina, "~> 2.7", only: [:dev, :test, :integration]},
      {:dialyxir, "~> 1.0", only: [:dev, :test, :integration], runtime: false},
      {:floki, "~> 0.33", only: [:dev, :test, :integration]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],

      # We want to be able to test seeding the data so mix ecto.reset no
      # longer seeds the database. This allows tests to
      # MIX_ENV=test mix ecto.reset && mix test
      "ecto.reset": ["ecto.drop", "ecto.create", "ecto.migrate"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
