defmodule ControlServerWeb.StatefulSetsTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  def stateful_sets_table(assigns) do
    ~H"""
    <.table id="stateful_sets" rows={@stateful_sets || []} row_click={&JS.navigate(resource_path(&1))}>
      <:col :let={stateful_set} label="Name">{name(stateful_set)}</:col>
      <:col :let={stateful_set} label="Namespace">{namespace(stateful_set)}</:col>
      <:col :let={stateful_set} label="Replicas">{replicas(stateful_set)}</:col>
      <:col :let={stateful_set} label="Available">{available_replicas(stateful_set)}</:col>

      <:action :let={stateful_set}>
        <.flex>
          <.button
            variant="minimal"
            link={resource_path(stateful_set)}
            icon={:eye}
            id={"stateful_set_show_link_" <> to_html_id(stateful_set)}
          />
          <.tooltip target_id={"stateful_set_show_link_" <> to_html_id(stateful_set)}>
            Show Stateful Set
          </.tooltip>
        </.flex>
      </:action>
    </.table>

    <.light_text :if={@stateful_sets == []}>No stateful sets available</.light_text>
    """
  end
end
