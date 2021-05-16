defmodule ControlServer.Settings.DevtoolsSettings do
  @moduledoc """
  Module around turning BaseService json config into usable settings.
  """
  @namespace "battery-devtools"
  import ControlServer.FileExt

  def namespace(config), do: config |> Map.get("namespace", @namespace)

  def gh_enabled(config), do: config |> Map.get("runner.enabled", true)
  def gh_app_id(config), do: config |> Map.get("runner.appid", "113520")
  def gh_install_id(config), do: config |> Map.get("runner.install_id", "16687509")

  def gh_private_key(config),
    do:
      config
      |> Map.get(
        "runner.priv_key",
        read_secure("battery-actions-runner-test1.2021-05-03.private-key.pem")
      )
end
