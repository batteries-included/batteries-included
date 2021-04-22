defmodule ControlServer.KubeExt do
  @moduledoc """
  Module to make working with K8s client a little bit easier.

  get_or_create/2 is the most useful.
  """
  require Logger

  def get_or_create(%{"items" => item_list}) do
    {:ok, Enum.map(item_list, fn i -> get_or_create_single(i) end)}
  end

  def get_or_create(resource) do
    get_or_create_single(resource)
  end

  def get_or_create_single(resource) do
    Logger.debug("Creating or getting #{inspect(resource)}")
    cluster_name = Bonny.Config.cluster_name()

    case resource
         |> K8s.Client.get()
         |> K8s.Client.run(cluster_name) do
      {:ok, _} = result ->
        result

      _ ->
        resource
        |> K8s.Client.create()
        |> K8s.Client.run(cluster_name)
    end
  end
end
