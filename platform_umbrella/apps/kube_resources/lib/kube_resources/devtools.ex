defmodule KubeResources.Devtools do
  alias KubeResources.DevtoolsSettings
  alias KubeResources.GithubActionsRunner

  @github_crd_path "priv/manifests/github/github_actions_runner-crds.yaml"

  def materialize(%{} = config) do
    static = %{
      "/0/crd" => yaml(github_crd_content())
    }

    %{} |> Map.merge(static) |> Map.merge(body(config)) |> Map.merge(runner(config))
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

  defp github_crd_content, do: unquote(File.read!(@github_crd_path))

  defp yaml(content) do
    content
    |> YamlElixir.read_all_from_string!()
    |> Enum.map(&KubeExt.Hashing.decorate_content_hash/1)
  end
end
