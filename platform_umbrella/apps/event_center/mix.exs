defmodule EventCenter.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_center,
      version: "0.7.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EventCenter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
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
end
