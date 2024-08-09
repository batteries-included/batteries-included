defmodule ControlServer.KubeSnapshotApplyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.SnapshotApply` context.
  """

  alias ControlServer.SnapshotApply.Kube

  @doc """
  Generate a resource_path.
  """
  def resource_path_fixture(attrs \\ %{}) do
    {:ok, resource_path} =
      attrs
      |> Enum.into(%{
        hash: "some hash",
        path: "/test",
        name: "test_obj",
        namespace: "default",
        type: :pod
      })
      |> Kube.create_resource_path()

    resource_path
  end

  @doc """
  Generate a kube_snapshot.
  """
  def kube_snapshot_fixture(attrs \\ %{}) do
    {:ok, kube_snapshot} =
      attrs
      |> Enum.into(%{
        status: :creation
      })
      |> Kube.create_kube_snapshot()

    kube_snapshot
  end
end
