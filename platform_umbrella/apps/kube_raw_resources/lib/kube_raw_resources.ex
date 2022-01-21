defmodule KubeRawResources do
  @moduledoc """
  Documentation for `KubeRawResources`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> KubeRawResources.hello()
      :world

  """
  def hello do
    :world
  end

  def world do
    KubeRawResources.Database.postgres_crd()
  end
end
