defmodule KubeServices.SnapshotApply.Stale do
  alias ControlServer.SnapshotApply, as: ControlSnapshot

  def is_stale(resource), do: has_annotation(resource) and not in_some_kube_snapshot(resource)

  def has_annotation(resource), do: K8s.Resource.has_annotation?(resource, KubeExt.Hashing.key())

  def in_some_kube_snapshot(resource) do
    ControlSnapshot.ResourcePath
    |> ControlSnapshot.resource_paths_recently()
    |> ControlSnapshot.resource_paths_for_resource(resource)
    |> ControlServer.Repo.exists?()
  end
end
