defmodule ControlServer.Umbrella.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.45.0",
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
        plt_ignore_apps: [:bandit, :myxql],
        plt_local_path: ".dialyzer",
        plt_core_path: ".dialyzer"
      ]
    ]
  end

  defp deps do
    [
      {:styler, "~> 1.1", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:credo_envvar, "~> 0.1", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 2.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:junit_formatter, "~> 3.4", only: [:dev, :test]}
    ]
  end

  defp releases do
    [
      control_server: [
        applications: [
          common_core: :permanent,
          control_server: :permanent,
          kube_services: :permanent,
          control_server_web: :permanent
        ],
        include_executables_for: [:unix],
        steps: [:assemble],
        runtime_config_path: "apps/control_server_web/config/runtime.exs"
      ],
      kube_bootstrap: [
        applications: [
          common_core: :permanent,
          kube_bootstrap: :permanent
        ],
        include_executables_for: [:unix],
        steps: [:assemble],
        runtime_config_path: "apps/kube_bootstrap/config/runtime.exs"
      ],
      home_base: [
        applications: [
          common_core: :permanent,
          home_base: :permanent,
          home_base_web: :permanent
        ],
        include_executables_for: [:unix],
        steps: [:assemble],
        runtime_config_path: "apps/home_base_web/config/runtime.exs"
      ]
    ]
  end

  defp aliases do
    [
      setup: ["cmd mix setup"],
      "ecto.reset": ["cmd mix ecto.reset"]
    ]
  end
end
