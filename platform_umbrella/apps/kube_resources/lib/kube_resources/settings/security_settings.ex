defmodule KubeResources.SecuritySettings do
  @moduledoc """
  Module around turning BaseService json config into usable settings.
  """
  @namespace "battery-core"

  def namespace(config), do: Map.get(config, "namespace", @namespace)
end
