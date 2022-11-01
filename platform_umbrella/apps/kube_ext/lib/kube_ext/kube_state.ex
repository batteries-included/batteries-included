defmodule KubeExt.KubeState do
  @moduledoc """
  Documentation for `KubeState`.
  """

  alias K8s.Resource
  alias KubeExt.ApiVersionKind
  alias KubeExt.KubeState.Runner

  @default_table :default_state_table

  def default_state_table, do: @default_table

  @spec snapshot(atom | :ets.tid()) :: map()
  def snapshot(t \\ @default_table) do
    Runner.snapshot(t)
  end

  @spec get(atom | :ets.tid(), map) :: nil | map()
  def get(t \\ @default_table, resource),
    do:
      get(
        t,
        ApiVersionKind.resource_type(resource),
        Resource.namespace(resource),
        Resource.name(resource)
      )

  @spec get(atom | :ets.tid(), atom, binary(), binary()) :: nil | map()
  def get(t \\ @default_table, resource_type, namespace, name) do
    Runner.get(t, resource_type, namespace, name)
  end

  @spec get_all(atom() | :ets.tid(), atom()) :: list(map)
  def get_all(t \\ @default_table, res_type) do
    Runner.get_all(t, res_type)
  end
end
