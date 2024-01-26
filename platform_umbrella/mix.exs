defmodule ControlServer.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.11.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      aliases: aliases(),
      test_coverage: [
        summary: [threshold: 30]
      ],
      dialyzer: [
        flags: ~w[error_handling unmatched_returns unknown]a,
        plt_add_deps: :app_tree,
        plt_add_apps: [:mix, :ex_unit, :dialyzer],
        plt_ignore_apps: [:bandit, :myxql]
      ]
    ]
  end

  defp deps do
    [
      {:styler, "~> 0.11", only: [:dev, :test, :integration], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test, :integration], runtime: false},
      {:credo_envvar, "~> 0.1", only: [:dev, :test, :integration], runtime: false},
      {:credo_naming, "~> 2.1", only: [:dev, :test, :integration], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test, :integration], runtime: false}
    ]
  end

  defp releases do
    [
      control_server: [
        applications: [
          control_server: :permanent,
          kube_services: :permanent,
          control_server_web: :permanent
        ],
        steps: [:assemble, &copy_configs/1],
        runtime_config_path: "apps/control_server_web/config/runtime.exs",
        config_providers: [
          {Config.Reader, {:system, "RELEASE_ROOT", "apps/control_server_web/config/runtime.exs"}}
        ]
      ],
      home_base: [
        applications: [home_base: :permanent, home_base_web: :permanent],
        steps: [:assemble, &copy_configs/1],
        runtime_config_path: "apps/home_base_web/config/runtime.exs",
        config_providers: [
          {Config.Reader, {:system, "RELEASE_ROOT", "apps/home_base_web/config/runtime.exs"}}
        ]
      ]
    ]
  end

  defp copy_configs(%{path: path, config_providers: config_providers} = release) do
    for {_module, {_context, _root, file_path}} <- config_providers do
      # Creating new path
      new_path = path <> Path.dirname(file_path)
      # Removing possible leftover files from previous builds
      File.rm_rf!(new_path)
      # Creating directory if it doesn't exist
      File.mkdir_p!(new_path)
      # Copying files to the directory with the same name
      File.cp!(Path.expand(file_path), new_path <> "/" <> Path.basename(file_path))
    end

    release
  end

  defp aliases do
    [
      setup: ["cmd mix setup"],
      "ecto.reset": ["cmd mix ecto.reset"]
    ]
  end
end
