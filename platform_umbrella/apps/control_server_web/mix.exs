defmodule ControlServerWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :control_server_web,
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
      mod: {ControlServerWeb.Application, []},
      extra_applications: [:logger, :runtime_tools, :dialyzer]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:integration), do: ["test/integration"]
  defp test_paths(:dev), do: ["test/unit", "test/integration"]
  defp test_paths(_), do: ["test/unit"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:common_core, in_umbrella: true},
      {:common_ui, in_umbrella: true},
      {:control_server, in_umbrella: true},
      {:kube_services, in_umbrella: true},
      {:bandit, "~> 1.4"},
      {:websock_adapter, "~> 0.5"},
      {:gettext, "~> 0.20"},
      {:inflex, "~> 2.1"},
      {:jason, "~> 1.4"},
      {:floki, "~> 0.36"},

      # K8s uses mint and mint_web_socket for HTTP requests
      # If it's detected as a dependency.
      {:k8s, "~> 2.6"},
      {:mint, "~> 1.0"},

      # We use this to generate some names
      {:mnemonic_slugs, "~> 0.0.3"},
      {:oidcc, "~> 3.2"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_view, "~> 0.20"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},

      # Development
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      # Testing
      {:wallaby, "~> 0.30", runtime: false, only: [:test, :integration]},
      {:ex_machina, "~> 2.7", only: [:dev, :test, :integration]},
      {:heyya, "~> 0.8", only: [:dev, :test, :integration]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "ecto.reset": []
    ]
  end
end
