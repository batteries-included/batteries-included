defmodule ControlServerWeb.StatefulSetsTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  def stateful_sets_table(assigns) do
    ~H"""
    <.table
      :if={@stateful_sets != []}
      id="stateful_sets"
      rows={@stateful_sets}
      row_click={&JS.navigate(resource_show_path(&1))}
    >
      <:col :let={stateful_set} label="Name"><%= name(stateful_set) %></:col>
      <:col :let={stateful_set} label="Namespace"><%= namespace(stateful_set) %></:col>
      <:col :let={stateful_set} label="Replicas"><%= replicas(stateful_set) %></:col>
      <:col :let={stateful_set} label="Available"><%= available_replicas(stateful_set) %></:col>

      <:action :let={stateful_set}>
        <.action_icon
          to={resource_show_path(stateful_set)}
          icon={:eye}
          tooltip="Show Stateful Set"
          id={"show_stateful_set" <> to_html_id(stateful_set)}
        />
      </:action>
    </.table>

    <.light_text :if={@stateful_sets == []}>No stateful sets available</.light_text>
    """
  end
end
