defmodule HomeBaseWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :home_base_web,
      version: "0.13.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_paths: test_paths(Mix.env()),
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {HomeBaseWeb.Application, []},
      extra_applications: [:logger, :runtime_tools, :dialyzer]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []

  defp deps do
    [
      {:common_ui, in_umbrella: true},
      {:home_base, in_umbrella: true},

      # Web Serving
      {:bandit, "~> 1.4"},
      {:websock_adapter, "~> 0.5"},
      {:gettext, "~> 0.20"},
      {:floki, "~> 0.36"},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_view, "~> 0.20"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},
      {:heyya, "~> 0.8", only: [:dev, :test, :integration]},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      # Token/Signing
      {:jose, "~> 1.11"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "ecto.reset": []
    ]
  end
end
