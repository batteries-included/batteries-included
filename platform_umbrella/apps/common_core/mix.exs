defmodule CommonCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :common_core,
      version: "0.12.4",
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
      mod: {CommonCore.Application, []},
      extra_applications: [:logger, :dialyzer]
    ]
  end

  defp deps do
    [
      # Nice naming generator
      {:mnemonic_slugs, "~> 0.0.3"},
      {:telemetry, "~> 1.1"},

      # Types for all the things
      {:typed_ecto_schema, "~> 0.4"},
      {:typed_struct, "~> 0.3", runtime: false},

      # For most of our HTTP client needs we use Tesla
      # with Finch as the adapter.
      {:tesla, "~> 1.9"},
      {:finch, "~> 0.18"},

      # K8s uses mint and mint_web_socket for HTTP requests
      # If it's detected as a dependency.
      {:k8s, "~> 2.6"},
      {:mint, "~> 1.0"},

      # Data Formats
      {:jason, "~> 1.4"},
      {:ymlr, "~> 5.1"},
      {:yaml_elixir, "~> 2.6"},

      # Password Hashing
      {:bcrypt_elixir, "~> 3.0"},

      # Token/Signing
      {:jose, "~> 1.11"},
      {:plug, "~> 1.16"},
      # History
      {:ex_audit, "~> 0.10"},

      # Testing
      {:mox, "~> 1.0", only: [:dev, :test, :integration], runtime: false},
      {:ex_machina, "~> 2.7", only: [:dev, :test, :integration]}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []
end
