defmodule KubeServices.KubeState.Behaviour do
  @moduledoc """
  Behaviour for Kubernetes state management modules.

  This behavior defines the interface for modules that manage Kubernetes
  resource state, typically backed by ETS tables.
  """

  @doc """
  Takes a snapshot of all resources in the state table.

  Returns a map representation of the current state.
  """
  @callback snapshot :: map()

  @doc """
  Gets a resource from the state table, raising if not found.

  Accepts either a resource map or individual parameters.
  """
  @callback get!(map()) :: map()
  @callback get!(atom(), binary() | nil, binary()) :: map()

  @doc """
  Gets a resource from the state table.

  Returns `{:ok, resource}` if found, `:missing` if not found.
  """
  @callback get(map()) :: :missing | {:ok, map()}
  @callback get(atom(), binary() | nil, binary()) :: :missing | {:ok, map()}

  @doc """
  Gets all resources of a given type from the state table.

  Returns a list of resources sorted by resource version.
  """
  @callback get_all(atom()) :: list(map)

  @doc """
  Gets resources owned by the specified owner(s).

  Accepts either a list of owner UIDs or a resource map containing a UID.
  """
  @callback get_owned_resources(atom(), list(String.t()) | map) :: list(map)

  @doc """
  Gets events related to a specific resource.

  Accepts either a resource UID or a resource map containing a UID.
  """
  @callback get_events(String.t() | map) :: list(map)
end
