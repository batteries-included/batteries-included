defmodule KubeExt.Yaml do
  def yaml(yaml_string_content) do
    yaml_string_content
    |> YamlElixir.read_all_from_string!()
    |> Enum.map(&KubeExt.Hashing.decorate/1)
  end

  def to_yaml(resource) do
    Ymlr.Encoder.to_s!(resource)
  end
end
