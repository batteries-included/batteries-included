defmodule ControlServer.SnapshotApplyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.SnapshotApply` context.
  """

  @doc """
  Generate a umbrella_snapshot.
  """
  def umbrella_snapshot_fixture(attrs \\ %{}) do
    {:ok, umbrella_snapshot} =
      attrs
      |> Map.new()
      |> ControlServer.SnapshotApply.Umbrella.create_umbrella_snapshot()

    umbrella_snapshot
  end
end
