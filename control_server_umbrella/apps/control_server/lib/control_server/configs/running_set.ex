defmodule ControlServer.Configs.RunningSet do
  @moduledoc """
  Module for working with the running set config. The running set
  config is a mapping of what should be running/installed in a cluster.
  Map[string, bool]
  """
  import Ecto.Query, warn: false
  require Logger
  alias ControlServer.Configs

  def get! do
    Configs.get_by_path!("/running_set")
  end

  def create do
    Configs.create_raw_config(%{
      path: "/running_set",
      content: %{"monitoring" => false}
    })
  end

  def set_running(%Configs.RawConfig{} = config, service_name, is_running \\ true) do
    new_content = %{config.content | service_name => is_running}

    with {:ok, result} <-
           Ecto.Multi.new()
           |> Ecto.Multi.run(:config, fn _repo, _changes ->
             Configs.update_raw_config(config, %{content: new_content})
           end)
           |> ControlServer.Repo.transaction() do
      {:ok, result[:config]}
    end
  end
end
