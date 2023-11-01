defmodule ControlServerWeb.StatefulSetsTable do
  @moduledoc false
  use ControlServerWeb, :html

  import ControlServerWeb.ResourceURL

  alias ControlServerWeb.Resource

  def stateful_sets_table(assigns) do
    ~H"""
    <.table
      :if={@stateful_sets != []}
      rows={@stateful_sets}
      row_click={&JS.navigate(resource_show_path(&1))}
    >
      <:col :let={stateful_set} label="Name"><%= Resource.name(stateful_set) %></:col>
      <:col :let={stateful_set} label="Namespace"><%= Resource.namespace(stateful_set) %></:col>
      <:col :let={stateful_set} label="Replicas"><%= get_in(stateful_set, ~w(spec replicas)) %></:col>
      <:col :let={stateful_set} label="Available">
        <%= get_in(stateful_set, ~w(status availableReplicas)) %>
      </:col>

      <:action :let={stateful_set}>
        <.action_icon
          to={resource_show_path(stateful_set)}
          icon={:eye}
          tooltip="Show Stateful Set"
          id={"show_stateful_set" <> Resource.id(stateful_set)}
        />
      </:action>
    </.table>

    <.light_text :if={@stateful_sets == []}>No stateful sets available</.light_text>
    """
  end
end
