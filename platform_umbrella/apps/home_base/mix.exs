defmodule HomeBase.MixProject do
  use Mix.Project

  def project do
    [
      app: :home_base,
      version: "0.12.2",
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
      {:bcrypt_elixir, "~> 3.0"},
      {:common_core, in_umbrella: true},
      {:ecto_sql, "~> 3.11"},
      {:ex_audit, "~> 0.10"},
      {:ex_machina, "~> 2.7", only: [:dev, :test, :integration]},
      {:flop, "~> 0.23"},
      {:jason, "~> 1.4"},
      {:mnemonic_slugs, "~> 0.0.3"},
      {:phoenix_ecto, "~> 4.5"},
      {:phoenix_pubsub, "~> 2.1"},
      {:swoosh, "~> 1.16"},
      {:hackney, "~> 1.9"},
      {:postgrex, "~> 0.17"},
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
