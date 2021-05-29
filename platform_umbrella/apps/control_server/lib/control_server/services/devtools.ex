defmodule ControlServer.Services.Devtools do
  @moduledoc """
  Module for dealing with all the Devtools related services
  """

  import ControlServer.FileExt

  alias ControlServer.Services
  alias ControlServer.Services.GithubActionsRunner
  alias ControlServer.Services.Security
  alias ControlServer.Settings.DevtoolsSettings

  @default_path "/Devtools/base"
  @default_config %{}

  def default_config, do: @default_config

  def activate(path \\ @default_path) do
    Security.activate()
    Services.update_active!(true, path, :devtools, @default_config)
  end

  def deactivate(path \\ @default_path),
    do: Services.update_active!(false, path, :devtools, @default_config)

  def active?(path \\ @default_path), do: Services.active?(path)

  def materialize(%{} = config) do
    static = %{
      "/0/crd" => read_yaml("github_actions_runner-crds.yaml", :exported),
      "/0/namespace" => namespace(config)
    }

    body =
      case DevtoolsSettings.gh_enabled(config) do
        true ->
          config
          |> GithubActionsRunner.materialize()
          |> Enum.map(fn {key, value} -> {"/1/body" <> key, value} end)
          |> Map.new()

        _ ->
          %{}
      end

    runners =
      case DevtoolsSettings.gh_enabled(config) do
        true ->
          %{"/2/runner" => runner(config)}

        _ ->
          %{}
      end

    %{} |> Map.merge(static) |> Map.merge(body) |> Map.merge(runners)
  end

  defp namespace(config) do
    ns = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Namespace",
      "metadata" => %{
        "name" => ns
      }
    }
  end

  defp runner(config) do
    ns = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "actions.summerwind.dev/v1alpha1",
      "kind" => "RunnerDeployment",
      "metadata" => %{
        "name" => "default-runner",
        "namespace" => ns
      },
      "spec" => %{
        "replicas" => 1,
        "template" => %{
          "spec" => %{
            "organization" => "batteries-included"
          }
        }
      }
    }
  end
end
