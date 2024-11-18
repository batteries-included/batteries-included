defmodule EventCenter.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_center,
      version: "0.36.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      test_paths: test_paths(Mix.env()),
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :dialyzer],
      mod: {EventCenter.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix_pubsub, "~> 2.1"},
      {:typed_struct, "~> 0.3", runtime: false}
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
