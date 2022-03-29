defmodule KubeState do
  @moduledoc """
  Documentation for `KubeState`.
  """

  @default_table :default_state_table

  @spec default_state_table :: :default_state_table
  def default_state_table, do: @default_table

  @spec namespaces(atom | :ets.tid()) :: list
  def namespaces(t \\ @default_table), do: get_all(t, :namespaces, [])

  @spec pods(atom | :ets.tid()) :: list
  def pods(t \\ @default_table), do: get_all(t, :pods, [])

  @spec services(atom | :ets.tid()) :: list
  def services(t \\ @default_table), do: get_all(t, :services, [])

  @spec deployments(atom | :ets.tid()) :: list
  def deployments(t \\ @default_table), do: get_all(t, :deployments, [])

  @spec stateful_sets(atom | :ets.tid()) :: list
  def stateful_sets(t \\ @default_table), do: get_all(t, :stateful_sets, [])

  @spec nodes(atom | :ets.tid()) :: list
  def nodes(t \\ @default_table), do: get_all(t, :nodes, [])

  def get_all(table, res_type) do
    case KubeState.Runner.get(table, res_type) do
      {:ok, result} ->
        result
    end
  end

  def get_all(table, res_type, default) do
    case KubeState.Runner.get(table, res_type) do
      {:ok, result} ->
        result

      _ ->
        default
    end
  end
end
