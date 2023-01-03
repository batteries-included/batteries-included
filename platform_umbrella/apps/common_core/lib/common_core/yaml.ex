defmodule CommonCore.Yaml do
  def yaml(yaml_string_content) do
    YamlElixir.read_all_from_string!(yaml_string_content)
  end

  def to_yaml(resource) do
    Ymlr.Encoder.to_s!(resource)
  end
end
