defmodule ControlServer.StaleSnaphotApply do
  @moduledoc false

  use ControlServer, :context

  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.ResourcePath

  @doc """
  Get the most recent resource paths from a snapshot.
  """
  @spec most_recent_snapshot_paths(non_neg_integer(), Ecto.Repo.t()) :: list(ResourcePath.t())
  def most_recent_snapshot_paths(num_snapshots \\ 10, repo \\ Repo) do
    # We don't need much here so limit what we fetch
    rp_query =
      from rp in ResourcePath,
        order_by: rp.path,
        select: [
          :name,
          :namespace,
          :type
        ]

    # Get the last num_snapshots by the last times they were updated
    # Then preload the resource paths with the specified fields
    # And then flatten
    KubeSnapshot
    |> order_by(desc: :updated_at)
    |> limit(^num_snapshots)
    |> preload(resource_paths: ^rp_query)
    |> repo.all()
    |> Enum.flat_map(& &1.resource_paths)
  end
end
