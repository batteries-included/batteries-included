defmodule KubeRawResources.Battery do
  import KubeExt.Yaml

  @bootstrapped_path "priv/manifests/battery/bootstrapped.yaml"

  def crd(_), do: yaml(bootstrapped_content())
  defp bootstrapped_content, do: unquote(File.read!(@bootstrapped_path))

  def materialize(config) do
    %{
      "/0/crd" => crd(config)
    }
  end
end
