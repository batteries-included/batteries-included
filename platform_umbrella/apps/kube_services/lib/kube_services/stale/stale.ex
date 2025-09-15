defmodule KubeServices.Stale do
  @moduledoc """
  A resource is considered stale if it meets certain criteria:

  - Has the correct management labels (`battery/managed.direct`)
  - Has the required annotations (hashing annotation)
  - Is not owned by another resource
  - Is not in a delete hold period
  - Is not present in recent resource snapshots

  ## Resource Classification

  Resources are classified based on several factors:

  ### Management Labels
  - `battery/managed.direct=true`: Resources directly managed by the platform
  - `battery/managed.indirect`: Resources indirectly managed (excluded from stale detection)

  ### Special Cases
  - Resources managed by `vm-operator` are excluded
  - Resources managed by Knative are excluded
  - Resources with owner references are excluded (controlled by other resources)

  ### Delete Hold
  Resources can specify a minimum lifetime using the `battery/delete-after` label
  with ISO 8601 duration format (e.g., "PT30M" for 30 minutes).
  """
  @behaviour KubeServices.Stale.Behaviour

  import CommonCore.Resources.FieldAccessors

  alias CommonCore.ApiVersionKind
  alias CommonCore.Resources.Hashing
  alias CommonCore.Resources.OwnerReference
  alias ControlServer.Repo
  alias ControlServer.SnapshotApply.Kube, as: ControlSnapshot
  alias ControlServer.SnapshotApply.ResourcePath
  alias ControlServer.StaleSnaphotApply
  alias KubeServices.KubeState

  require Logger

  @empty MapSet.new()
  @num_resource_snapshots 3

  @spec can_delete_safe? :: boolean
  def can_delete_safe?, do: resource_paths_success?() and snapshot_success?()

  @spec find_potential_stale :: list
  def find_potential_stale do
    seen_res_set = recent_resource_map_set(@num_resource_snapshots)

    KubeState.snapshot()
    |> Enum.flat_map(fn {_key, values} -> values end)
    |> Enum.filter(fn r ->
      stale?(r, seen_res_set)
    end)
  end

  @spec stale?(map, MapSet.t() | nil) :: boolean
  def stale?(resource, seen_res_set \\ nil)
  def stale?(resource, nil), do: stale?(resource, recent_resource_map_set())
  def stale?(resource, seen_res_set) when seen_res_set == @empty, do: stale?(resource, recent_resource_map_set())

  def stale?(r, seen_res_set) do
    case {has_owners?(r), good_labels?(r), has_annotation?(r), in_delete_hold?(r), to_tuple(r)} do
      # If this resource is owned by something then is directly controlled by us
      {true, _, _, _, _} ->
        false

      # We need to have the direct label to be potentially stale
      {_, false, _, _, _} ->
        false

      # We need to have the annotation since there's no way to push without it
      {_, _, false, _, _} ->
        false

      # If we're in delete hold, resource isn't stale
      {_, _, _, true, _} ->
        false

      # We need to have been able to make an apiversionkind tuple
      {_, _, _, _, {:error, _}} ->
        false

      # If all of those things are ok this
      # might be stale if the
      # matching {type, namespace, name} tuple is not in the set.
      {false, true, true, false, {:ok, tup}} ->
        !MapSet.member?(seen_res_set, tup)
    end
  end

  defp recent_resource_map_set(num_snapshots \\ @num_resource_snapshots) do
    num_snapshots
    |> StaleSnaphotApply.most_recent_snapshot_paths()
    |> MapSet.new(&to_tuple!/1)
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
    |> OwnerReference.get_all_owners()
    |> Enum.empty?() == false
  end

  @spec has_annotation?(nil | map) :: boolean
  defp has_annotation?(%{} = resource), do: K8s.Resource.has_annotation?(resource, Hashing.key())

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
    has_label?(resource, "battery/managed.direct") && label(resource, "battery/managed.direct") == "true"
  end

  defp has_indirect_label(resource) do
    has_label?(resource, "battery/managed.indirect")
  end

  # allow specifying a minimum resource lifetime using ISO 8601 duration format e.g. PT30M, etc
  defp in_delete_hold?(resource) do
    has_label?(resource, "battery/delete-after") && in_delete_hold_window?(resource)
  end

  defp in_delete_hold_window?(resource) do
    duration = K8s.Resource.label(resource, "battery/delete-after")

    with {:ok, created_at, _} <- resource |> creation_timestamp() |> DateTime.from_iso8601(),
         {:ok, offset} <- Duration.from_iso8601(duration),
         comparison = DateTime.shift(created_at, offset),
         {:ok, now} <- DateTime.now("Etc/UTC") do
      # now is before the requested delete time
      :lt == DateTime.compare(now, comparison)
    else
      err ->
        Logger.error("error checking delete after label: #{inspect(err)}")
        false
    end
  end

  defp managed_by_vm_operator(resource) do
    has_label?(resource, "managed-by") && label(resource, "managed-by") == "vm-operator"
  end

  defp managed_by_knative(resource) do
    has_label?(resource, "serving.knative.dev/service")
  end

  defp snapshot_success? do
    ControlServer.SnapshotApply.KubeSnapshot
    |> ControlSnapshot.snapshot_recently()
    |> ControlSnapshot.snapshot_success()
    |> Repo.exists?()
  end

  defp resource_paths_success? do
    ResourcePath
    |> ControlSnapshot.resource_paths_recently()
    |> ControlSnapshot.resource_paths_success()
    |> Repo.exists?()
  end
end
