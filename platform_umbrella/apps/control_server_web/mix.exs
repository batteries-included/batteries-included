defmodule ControlServerWeb.MixProject do
  use Mix.Project

  def project do
    [
      app: :control_server_web,
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
      {:dialyxir, "~> 1.0", only: [:dev, :test, :integration], runtime: false},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:ex_machina, "~> 2.7", only: [:dev, :test, :integration]},
      {:floki, "~> 0.35", only: [:dev, :test, :integration], override: true},
      {:gettext, "~> 0.20"},
      {:heroicons, "~> 0.5"},
      {:heyya, "~> 0.7", only: [:dev, :test, :integration]},
      {:inflex, "~> 2.1"},
      {:jason, "~> 1.4"},
      {:junit_formatter, "~> 3.3", only: [:dev, :test, :integration]},
      {:kube_services, in_umbrella: true},
      {:mint, "~> 1.0"},
      {:mnemonic_slugs, "~> 0.0.3"},
      {:oidcc, "~> 3.1.0-beta.2", override: true},
      {:petal_components, "~> 1.7"},
      {:phoenix, "~> 1.7"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_storybook, "~> 0.5"},
      {:plug_cowboy, "~> 2.6"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:wallaby, "~> 0.30", runtime: false, only: [:test, :integration]},
      {:websock_adapter, "~> 0.5"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild.deploy", "css.deploy", "phx.digest"],
      "css.deploy": ["cmd npm run deploy --prefix assets"],
      "esbuild.deploy": ["esbuild control_server_web --minify --analyze"],
      "ecto.reset": []
    ]
  end
end
