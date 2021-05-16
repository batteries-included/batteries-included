defmodule ControlServer.Settings.SecuritySettings do
  @moduledoc """
  Module around turning BaseService json config into usable settings.
  """
  @namespace "battery-security"

  def namespace(config), do: config |> Map.get("namespace", @namespace)
end
