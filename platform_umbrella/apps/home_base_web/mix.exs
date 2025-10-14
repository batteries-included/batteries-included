defmodule HomeBaseWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :home_base_web,
      version: "1.11.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_paths: test_paths(Mix.env()),
      aliases: aliases(),
      deps: deps(),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: listeners()
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
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.6"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.1"},
      {:heyya, "~> 2.0", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 1.1"},
      {:flop_phoenix, "~> 0.25"},

      # Log to json
      {:logger_json, "~> 7.0.0"},
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

  defp listeners do
    if dependabot?(), do: [], else: [Phoenix.CodeReloader]
  end

  defp dependabot? do
    Enum.any?(System.get_env(), fn {key, _value} -> String.starts_with?(key, "DEPENDABOT") end)
  end
end
