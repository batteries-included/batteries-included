defmodule KubeResources.Security do
  import KubeResources.FileExt

  alias KubeResources.CertManager
  alias KubeResources.SecuritySettings

  def materialize(%{} = config) do
    static = %{
      "/0/crd" => read_yaml("cert_manager/cert_manager-crds.yaml", :base),
      "/0/namespace" => namespace(config)
    }

    body =
      config
      |> CertManager.materialize()
      |> Enum.map(fn {key, value} -> {"/1/body" <> key, value} end)
      |> Map.new()

    %{} |> Map.merge(static) |> Map.merge(body)
  end

  defp namespace(config) do
    ns = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Namespace",
      "metadata" => %{
        "name" => ns
      }
    }
  end
end
