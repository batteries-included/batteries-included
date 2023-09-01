defmodule EventCenter.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_center,
      version: "0.8.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      test_paths: test_paths(Mix.env()),
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :dialyzer],
      mod: {EventCenter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev, :test, :integration], runtime: false},
      {:typed_struct, "~> 0.3.0", runtime: false},
      # Braodcast to thos who need events
      {:phoenix_pubsub, "~> 2.1"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "ecto.reset": []
    ]
  end

  defp test_paths(:test), do: ["test"]
  defp test_paths(_), do: []
end
