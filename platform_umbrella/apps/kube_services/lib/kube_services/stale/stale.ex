defmodule KubeServices.Stale do
  import K8s.Resource.FieldAccessors

  alias ControlServer.SnapshotApply, as: ControlSnapshot
  alias ControlServer.Repo
  alias KubeExt.KubeState
  alias KubeExt.Hashing
  alias KubeExt.ApiVersionKind

  require Logger

  @spec find_stale :: list
  def find_stale do
    KubeState.table_to_list()
    |> Enum.map(fn kv -> elem(kv, 1) end)
    |> Enum.filter(&has_annotation/1)
    |> Enum.reject(fn r -> in_some_kube_snapshot(r) end)
    |> log_scan_results()
  end

  @spec has_annotation(nil | map) :: boolean
  def has_annotation(%{} = resource),
    do: K8s.Resource.has_annotation?(resource, Hashing.key())

  def has_annotation(nil), do: false

  @spec in_some_kube_snapshot(map) :: boolean
  def in_some_kube_snapshot(resource) do
    ControlSnapshot.ResourcePath
    |> ControlSnapshot.resource_paths_recently()
    |> ControlSnapshot.resource_paths_by_type(ApiVersionKind.resource_type!(resource))
    |> ControlSnapshot.resource_paths_by_name(name(resource))
    |> ControlSnapshot.resource_paths_by_namespace(namespace(resource))
    |> Repo.exists?()
  end

  @spec can_delete_safe? :: boolean
  def can_delete_safe?, do: resource_paths_success?() and snapshot_success?()

  defp snapshot_success? do
    ControlSnapshot.KubeSnapshot
    |> ControlSnapshot.snapshot_recently()
    |> ControlSnapshot.snapshot_success()
    |> Repo.exists?()
  end

  defp resource_paths_success? do
    ControlSnapshot.ResourcePath
    |> ControlSnapshot.resource_paths_recently()
    |> ControlSnapshot.resource_paths_success()
    |> Repo.exists?()
  end

  defp log_scan_results(results) do
    Logger.info("Found #{length(results)} stale resources that can be deleted.")
    results
  end
end
