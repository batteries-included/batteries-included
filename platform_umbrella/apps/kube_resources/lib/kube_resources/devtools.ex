defmodule KubeResources.Devtools do
  import KubeExt.Yaml

  alias KubeResources.DevtoolsSettings
  alias KubeResources.GithubActionsRunner
  alias KubeResources.KnativeOperator

  @github_crd_path "priv/manifests/github/github_actions_runner-crds.yaml"
  @knative_crd_path "priv/manifests/knative/operator-crds.yaml"

  def materialize(%{} = config) do
    static = %{
      "/0/github_crd" => yaml(github_crd_content()),
      "/0/knative_crd" => yaml(knative_crd_content())
    }

    %{}
    |> Map.merge(static)
    |> Map.merge(body(config))
    |> Map.merge(runner(config))
    |> Map.merge(knative(config))
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

  def knative(config) do
    config
    |> KnativeOperator.materialize()
    |> Enum.map(fn {key, value} -> {"/3/knative" <> key, value} end)
    |> Enum.into(%{})
  end

  defp github_crd_content, do: unquote(File.read!(@github_crd_path))
  defp knative_crd_content, do: unquote(File.read!(@knative_crd_path))
end
