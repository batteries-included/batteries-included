defmodule KubeServices.Stale do
  import K8s.Resource.FieldAccessors

  alias ControlServer.SnapshotApply, as: ControlSnapshot
  alias ControlServer.StaleSnaphotApply
  alias ControlServer.SnapshotApply.ResourcePath
  alias ControlServer.Repo
  alias KubeExt.KubeState
  alias KubeExt.Hashing
  alias CommonCore.ApiVersionKind

  require Logger

  @spec find_potential_stale :: list
  def find_potential_stale do
    seen_res_set = recent_resource_map_set(1)

    KubeState.snapshot()
    |> Enum.flat_map(fn {_key, values} -> values end)
    |> Enum.filter(fn r ->
      is_stale(r, seen_res_set)
    end)
  end

  def is_stale(resource, seen_res_set \\ nil)
  def is_stale(resource, nil), do: is_stale(resource, recent_resource_map_set())

  def is_stale(r, seen_res_set) do
    case {has_owners?(r), good_labels?(r), has_annotation?(r), to_tuple(r)} do
      # If this resource is owned by something then is directly controlled by us
      {true, _, _, _} ->
        false

      # We need to have the direct label to be potentially stale
      {_, false, _, _} ->
        false

      # We need to have the annotation since there's no way to push without it
      {_, _, false, _} ->
        false

      # We need to have been able to make an apiversionkind tuple
      {_, _, _, {:error, _}} ->
        false

      # If all of those things are ok this
      # might be stale if the
      # matching {type, namespace, name} tuple is not in the set.
      {false, true, true, {:ok, tup}} ->
        !MapSet.member?(seen_res_set, tup)
    end
  end

  def recent_resource_map_set(num_snapshots \\ 10) do
    num_snapshots
    |> StaleSnaphotApply.most_recent_snapshot_paths()
    |> Enum.map(&to_tuple!/1)
    |> MapSet.new()
  end

  defp to_tuple!(r) do
    case to_tuple(r) do
      {:ok, tuple} -> tuple
      {:error, reason} -> raise "Can't create the tuple Reason: #{reason}"
    end
  end

  defp to_tuple(%ResourcePath{} = r), do: {:ok, {r.type, r.namespace, r.name}}

  defp to_tuple(%{} = r) do
    case ApiVersionKind.resource_type(r) do
      nil -> {:error, reason: "can't findApiVersion"}
      type -> {:ok, {type, namespace(r), name(r)}}
    end
  end

  defp has_owners?(nil), do: false

  defp has_owners?(%{} = res) do
    res
    |> KubeExt.OwnerReference.get_all_owners()
    |> Enum.empty?() == false
  end

  @spec has_annotation?(nil | map) :: boolean
  defp has_annotation?(%{} = resource),
    do: K8s.Resource.has_annotation?(resource, Hashing.key())

  defp has_annotation?(nil), do: false

  @spec good_labels?(nil | map) :: boolean
  defp good_labels?(%{} = resource) do
    has_direct_label(resource) &&
      !has_indirect_label(resource) &&
      !managed_by_vm_operator(resource) &&
      !managed_by_knative(resource)
  end

  defp good_labels?(nil = _resource), do: false

  defp has_direct_label(resource) do
    K8s.Resource.has_label?(resource, "battery/managed.direct") &&
      K8s.Resource.label(resource, "battery/managed.direct") == "true"
  end

  defp has_indirect_label(resource) do
    K8s.Resource.has_label?(resource, "battery/managed.indirect")
  end

  defp managed_by_vm_operator(resource) do
    K8s.Resource.has_label?(resource, "managed-by") &&
      K8s.Resource.label(resource, "managed-by") == "vm-operator"
  end

  defp managed_by_knative(resource) do
    K8s.Resource.has_label?(resource, "serving.knative.dev/service")
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
end
