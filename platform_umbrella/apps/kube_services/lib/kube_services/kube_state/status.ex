defmodule KubeServices.KubeState.Status do
  @moduledoc false
  use Agent

  def start_link(_opts), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @spec update(:ets.table()) :: :ok
  def update(table_name), do: Agent.update(__MODULE__, &Map.put(&1, table_name, DateTime.utc_now()))

  @spec get(:ets.table()) :: DateTime.t() | nil
  def get(table_name), do: Agent.get(__MODULE__, &Map.get(&1, table_name))
end
