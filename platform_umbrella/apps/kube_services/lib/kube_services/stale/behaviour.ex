defmodule KubeServices.Stale.Behaviour do
  @moduledoc false
  @doc """
  Checks if it's safe to delete stale resources.

  This function verifies that both resource paths and snapshots have been
  successfully captured recently. This ensures the system has accurate
  information about the current state before allowing stale resource deletion.

  ## Returns

  - `true` if both resource paths and snapshots are recent and successful
  - `false` if either check fails, indicating deletion should be deferred

  ## Examples

      iex> MyStaleImpl.can_delete_safe?()
      true

      iex> MyStaleImpl.can_delete_safe?()
      false
  """
  @callback can_delete_safe?() :: boolean()

  @doc """
  Finds all potentially stale resources in the current Kubernetes state.

  This function examines the current Kubernetes state snapshot and identifies
  resources that may be stale based on the stale detection criteria. It compares
  the current state against the most recent resource snapshot to determine
  which resources are no longer actively managed.

  ## Returns

  A list of Kubernetes resource maps that are potentially stale. Each resource
  in the list will have:
  - Correct management labels
  - Required annotations
  - No owner references
  - Not in delete hold period
  - Not present in recent snapshots

  ## Examples

      iex> MyStaleImpl.find_potential_stale()
      [
        %{
          "apiVersion" => "v1",
          "kind" => "ConfigMap",
          "metadata" => %{
            "name" => "old-config",
            "namespace" => "default",
            "labels" => %{"battery/managed.direct" => "true"}
          }
        }
      ]

      iex> MyStaleImpl.find_potential_stale()
      []
  """
  @callback find_potential_stale() :: [map()]

  @doc """
  Determines if a specific resource is stale.

  This is the core stale detection logic that evaluates a single resource
  against the stale criteria. The function can optionally accept a pre-computed
  set of recent resources for performance optimization when checking multiple resources.

  ## Parameters

  - `resource` - The Kubernetes resource map to evaluate
  - `seen_res_set` - Optional MapSet of recent resources for performance optimization

  ## Stale Criteria

  A resource is considered stale if ALL of the following conditions are met:
  1. Does not have owner references (not controlled by another resource)
  2. Has the `battery/managed.direct=true` label
  3. Does not have the `battery/managed.indirect` label
  4. Is not managed by vm-operator or Knative
  5. Has the required hashing annotation
  6. Is not in a delete hold period
  7. Is not present in recent resource snapshots

  ## Returns

  - `true` if the resource is stale and can be deleted
  - `false` if the resource should be preserved

  ## Examples

      iex> resource = %{
      ...>   "metadata" => %{
      ...>     "labels" => %{"battery/managed.direct" => "true"},
      ...>     "annotations" => %{"battery/hash" => "abc123"}
      ...>   }
      ...> }
      iex> MyStaleImpl.stale?(resource)
      true

      iex> owned_resource = %{
      ...>   "metadata" => %{
      ...>     "ownerReferences" => [%{"kind" => "Deployment"}],
      ...>     "labels" => %{"battery/managed.direct" => "true"}
      ...>   }
      ...> }
      iex> MyStaleImpl.stale?(owned_resource)
      false
  """
  @callback stale?(resource :: map(), seen_res_set :: MapSet.t() | nil) :: boolean()

  @doc """
  Determines if a specific resource is stale using default recent resource set.

  This is a convenience function that calls `stale?/2` with a `nil` seen_res_set,
  causing it to compute the recent resource set automatically.

  ## Parameters

  - `resource` - The Kubernetes resource map to evaluate

  ## Returns

  - `true` if the resource is stale and can be deleted
  - `false` if the resource should be preserved

  ## Examples

      iex> resource = %{
      ...>   "metadata" => %{
      ...>     "labels" => %{"battery/managed.direct" => "true"},
      ...>     "annotations" => %{"battery/hash" => "abc123"}
      ...>   }
      ...> }
      iex> MyStaleImpl.stale?(resource)
      true
  """
  @callback stale?(resource :: map()) :: boolean()
end
