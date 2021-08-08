defmodule KubeResources.DevtoolsSettings do
  @moduledoc """
  Module around turning BaseService json config into usable settings.
  """
  @namespace "battery-devtools"

  def namespace(config), do: Map.get(config, "namespace", @namespace)
  def gh_enabled(config), do: Map.get(config, "runner.enabled", true)
  def gh_app_id(config), do: Map.get(config, "runner.appid", "113520")
  def gh_install_id(config), do: Map.get(config, "runner.install_id", "16687509")

  def gh_private_key(config),
    do:
      Map.get(
        config,
        "runner.priv_key",
        ""
      )
end
