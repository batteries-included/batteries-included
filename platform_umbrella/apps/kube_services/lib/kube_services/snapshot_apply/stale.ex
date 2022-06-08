defmodule KubeServices.SnapshotApply.Stale do
  import K8s.Resource.FieldAccessors

  alias ControlServer.SnapshotApply, as: ControlSnapshot
  alias ControlServer.Repo
  alias KubeExt.KubeState

  require Logger

  def find_stale do
    KubeState.table_to_list()
    |> Enum.map(fn kv -> elem(kv, 1) end)
    |> Enum.filter(&is_stale/1)
    |> log_scan_results()
  end

  def is_stale(resource), do: has_annotation(resource) and not in_some_kube_snapshot(resource)

  def has_annotation(resource), do: K8s.Resource.has_annotation?(resource, KubeExt.Hashing.key())

  def in_some_kube_snapshot(resource) do
    ControlSnapshot.ResourcePath
    |> ControlSnapshot.resource_paths_recently()
    |> ControlSnapshot.resource_paths_by_api_version(api_version(resource))
    |> ControlSnapshot.resource_paths_by_kind(kind(resource))
    |> ControlSnapshot.resource_paths_by_name(name(resource))
    |> ControlSnapshot.resource_paths_by_namespace(namespace(resource))
    |> Repo.exists?()
  end

  defp log_scan_results(results) do
    Logger.info("Found #{length(results)} stale resources that can be deleted.")
    results
  end
end
