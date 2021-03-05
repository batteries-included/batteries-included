defmodule Server.Configs.RunningSet do
  @moduledoc """
  Module for working with the running set config. The running set
  config is a mapping of what should be running/installed in a cluster.
  Map[string, bool]
  """
  import Ecto.Query, warn: false
  alias Server.Configs

  def get!() do
    Configs.get_by_path!("/running_set")
  end

  def create() do
    Configs.create_raw_config(%{
      path: "/running_set",
      content: %{"monitoring" => false}
    })
  end

  def set_running(config, service_name, is_running \\ true) do
    new_content = %{config.content | service_name => is_running}

    config
    |> Configs.update_raw_config(%{content: new_content})
  end
end
