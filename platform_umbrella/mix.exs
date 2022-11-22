defmodule ControlServer.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.4.0",
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
        plt_add_apps: [:mix]
      ]
    ]
  end

  defp deps do
    [
      {:bakeware, "~> 0.2.4"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:credo_envvar, "~> 0.1", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 2.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.11", only: :dev}
    ]
  end

  defp releases do
    [
      control_server: [
        applications: [
          control_server: :permanent,
          kube_ext: :permanent,
          kube_services: :permanent,
          control_server_web: :permanent
        ]
      ],
      home_base: [
        applications: [home_base: :permanent, home_base_web: :permanent]
      ],
      cli: [
        applications: [cli: :permanent, kube_resources: :permanent, kube_ext: :permanent],
        runtime_config_path: "apps/cli/config/releases.exs",
        config_providers: config_providers_for_apps([:cli]),
        steps: [:assemble, &copy_configs/1, &Bakeware.assemble/1]
      ]
    ]
  end

  defp config_providers_for_apps(apps) do
    for app <- apps do
      {Config.Reader,
       path: {:system, "RELEASE_ROOT", "/apps/#{app}/config/releases.exs"}, env: Mix.env()}
    end
  end

  # When assembling the release, we copy all the releases.exs files defined
  # in `config_providers` to it, keeping the
  # relative app path to avoid collisions.
  defp copy_configs(
         %Mix.Release{path: release_directory_path, config_providers: config_providers} = release
       ) do
    for {_module, path: {_context, _root, config_file_path}, env: _} <- config_providers do
      config_directory = Path.join(release_directory_path, Path.dirname(config_file_path))

      # Clean the config directory to make sure we
      # are only including the files defined in
      # the config_providers
      File.rm_rf!(config_directory)
      File.mkdir_p!(config_directory)

      File.cp!(
        Path.relative(config_file_path),
        Path.join(config_directory, Path.basename(config_file_path))
      )
    end

    release
  end

  defp aliases do
    [
      setup: ["cmd mix setup"],
      "ecto.reset": ["cmd mix ecto.reset"],
      prettier:
        "cmd --app control_server_web --cd ../.. ./apps/control_server_web/assets/node_modules/.bin/prettier -w . --color",
      prettier_check:
        "cmd --app control_server_web --cd ../.. ./apps/control_server_web/assets/node_modules/.bin/prettier --check . --color"
    ]
  end
end
