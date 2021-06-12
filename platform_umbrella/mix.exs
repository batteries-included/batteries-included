defmodule ControlServer.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      releases: releases(),
      aliases: aliases()
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:credo_envvar, "~> 0.1", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:surface_formatter,
       github: "surface-ui/surface_formatter",
       branch: "support-new-surface-syntax",
       only: :dev,
       runtime: false},
      {:surface, github: "surface-ui/surface", override: true},
      {:excoveralls, "~> 0.14", only: :test}
    ]
  end

  defp releases do
    [
      control_server: [
        applications: [control_server: :permanent, control_server_web: :permanent]
      ],
      bootstrap: [
        applications: [control_server: :permanent]
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  #
  # Aliases listed here are available only for this project
  # and cannot be accessed from applications inside the apps/ folder.
  defp aliases do
    [
      # run `mix setup` in all child apps
      setup: ["cmd mix setup"],
      "ecto.reset": ["cmd mix ecto.reset"],
      fmt: ["format", "surface.format", "prettier"],
      "fmt.check": ["format --check-formatted", "prettier_check"],
      prettier:
        "cmd --app control_server_web --cd ../.. ./apps/control_server_web/assets/node_modules/.bin/prettier -w . --color",
      prettier_check:
        "cmd --app control_server_web --cd ../.. ./apps/control_server_web/assets/node_modules/.bin/prettier --check . --color"
    ]
  end
end
