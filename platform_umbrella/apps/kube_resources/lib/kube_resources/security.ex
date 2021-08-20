defmodule KubeResources.Security do
  alias KubeResources.CertManager

  @certmanager_crd_path "priv/manifests/cert_manager/cert_manager-crds.yaml"

  def materialize(%{} = config) do
    static = %{
      "/0/crd" => yaml(certmanager_crd_content())
    }

    body =
      config
      |> CertManager.materialize()
      |> Enum.map(fn {key, value} -> {"/1/body" <> key, value} end)
      |> Map.new()

    %{} |> Map.merge(static) |> Map.merge(body)
  end

  defp certmanager_crd_content, do: unquote(File.read!(@certmanager_crd_path))

  defp yaml(content) do
    content
    |> YamlElixir.read_all_from_string!()
    |> Enum.map(&KubeExt.Hashing.decorate_content_hash/1)
  end
end
