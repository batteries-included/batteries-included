defmodule CommonUI.MixProject do
  use Mix.Project

  def project do
    [
      app: :common_ui,
      version: "0.12.1",
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
      mod: {CommonUI.Application, []},
      extra_applications: [:logger, :runtime_tools, :dialyzer]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:integration), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.4"},
      {:floki, "~> 0.36", only: [:dev, :test, :integration]},
      {:heroicons, "~> 0.5"},
      {:heyya, "~> 0.8", only: [:dev, :test, :integration]},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 0.20", override: true},
      {:phoenix_storybook, "~> 0.6"},
      {:timex, "~> 3.7"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      "ecto.reset": []
    ]
  end
end
