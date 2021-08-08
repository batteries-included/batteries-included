defmodule KubeResources.Devtools do
  import KubeResources.FileExt

  alias KubeResources.DevtoolsSettings
  alias KubeResources.GithubActionsRunner

  def materialize(%{} = config) do
    static = %{
      "/0/crd" => read_yaml("github/github_actions_runner-crds.yaml", :base),
      "/0/namespace" => namespace(config)
    }

    %{} |> Map.merge(static) |> Map.merge(body(config)) |> Map.merge(runner(config))
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

    case DevtoolsSettings.gh_enabled(config) do
      true ->
        %{
          "/2/runner" => %{
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
        }

      _ ->
        %{}
    end
  end

  defp body(config) do
    case DevtoolsSettings.gh_enabled(config) do
      true ->
        config
        |> GithubActionsRunner.materialize()
        |> Enum.map(fn {key, value} -> {"/1/body" <> key, value} end)
        |> Map.new()

      _ ->
        %{}
    end
  end
end
