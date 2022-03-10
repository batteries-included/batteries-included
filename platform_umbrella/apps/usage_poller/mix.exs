defmodule UsagePoller.MixProject do
  use Mix.Project

  def project do
    [
      app: :usage_poller,
      version: "0.3.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {UsagePoller.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:control_server, in_umbrella: true},
      {:kube_ext, in_umbrella: true},
      {:k8s, "~> 1.1"},
      {:event_center, in_umbrella: true}
    ]
  end

  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["deps.get"],
      "ecto.reset": [],
      fmt: ["format"]
    ]
  end
end
