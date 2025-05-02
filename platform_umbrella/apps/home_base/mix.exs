defmodule HomeBase.MixProject do
  use Mix.Project

  def project do
    [
      app: :home_base,
      version: "0.69.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: test_paths(Mix.env()),
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
      mod: {HomeBase.Application, []},
      extra_applications: [:logger, :runtime_tools, :dialyzer]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:common_core, in_umbrella: true},
      {:ecto_soft_delete, "~> 2.0"},
      {:ecto_sql, "~> 3.11"},
      {:ex_audit, "~> 0.10"},
      {:ex_machina, "~> 2.7", only: [:dev, :test]},
      {:mox, "~> 1.0", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.4"},
      {:mnemonic_slugs, "~> 0.0.3"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_pubsub, "~> 2.1"},
      {:swoosh, "~> 1.16"},
      {:finch, "~> 0.18"},
      {:postgrex, "~> 0.18"},
      {:typed_ecto_schema, "~> 0.4"},
      {:yaml_elixir, "~> 2.6"},
      {:ymlr, "~> 5.0"}
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
