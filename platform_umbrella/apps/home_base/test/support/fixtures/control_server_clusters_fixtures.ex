defmodule HomeBase.ControlServerClustersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HomeBase.ControlServerClusters` context.
  """

  @doc """
  Generate a installation.
  """
  def installation_fixture(attrs \\ %{}) do
    {:ok, installation} =
      attrs
      |> Enum.into(%{
        slug: "some-likey-unique-slug"
      })
      |> HomeBase.ControlServerClusters.create_installation()

    installation
  end
end
