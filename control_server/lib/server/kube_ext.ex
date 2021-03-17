defmodule Server.KubeExt do
  @moduledoc """
  Module to make working with K8s client a little bit easier.

  get_or_create/2 is the most useful.
  """
  require Logger

  def get_or_create(%{"items" => item_list}, client) do
    {:ok, Enum.map(item_list, fn i -> get_or_create_single(i, client) end)}
  end

  def get_or_create(resource, client) do
    get_or_create_single(resource, client)
  end

  def get_or_create_single(resource, client) do
    Logger.debug("Creating or getting #{inspect(resource)}")
    cluster_name = Bonny.Config.cluster_name()

    case resource
         |> client.get()
         |> client.run(cluster_name) do
      {:ok, _} = result ->
        result

      _ ->
        resource
        |> client.create()
        |> client.run(cluster_name)
    end
  end
end
