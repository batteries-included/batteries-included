defmodule Server.ComputedConfigs do
  @moduledoc """
  Rather than configs just in the db these will be configs that are
  computed in some way. For example we could combine multiple configs.
  """
  alias Server.Configs
  alias Server.Configs.RawConfig

  def get("/prometheus/main" = path) do
    %RawConfig{} = base_config = Configs.get_by_path!("/prometheus/base")
    {:ok, %{path: path, content: base_config.content}}
  end

  def get(path) do
    {:ok, Configs.get_by_path!(path)}
  end
end
