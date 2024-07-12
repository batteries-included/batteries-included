defmodule ControlServerWeb.StatefulSetsTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  def stateful_sets_table(assigns) do
    ~H"""
    <.table id="stateful_sets" rows={@stateful_sets || []} row_click={&JS.navigate(resource_path(&1))}>
      <:col :let={stateful_set} label="Name"><%= name(stateful_set) %></:col>
      <:col :let={stateful_set} label="Namespace"><%= namespace(stateful_set) %></:col>
      <:col :let={stateful_set} label="Replicas"><%= replicas(stateful_set) %></:col>
      <:col :let={stateful_set} label="Available"><%= available_replicas(stateful_set) %></:col>
    </.table>

    <.light_text :if={@stateful_sets == []}>No stateful sets available</.light_text>
    """
  end
end
