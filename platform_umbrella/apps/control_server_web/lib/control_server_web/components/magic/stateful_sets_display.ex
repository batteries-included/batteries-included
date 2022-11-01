defmodule ControlServerWeb.StatefulSetsDisplay do
  use ControlServerWeb, :html

  import ControlServerWeb.ResourceURL
  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  def stateful_sets_display(assigns) do
    ~H"""
    <.table id="stateful_set-display-table" rows={@stateful_sets}>
      <:col :let={stateful_set} label="Namespace"><%= namespace(stateful_set) %></:col>
      <:col :let={stateful_set} label="Name"><%= name(stateful_set) %></:col>
      <:col :let={stateful_set} label="Replicas"><%= get_in(stateful_set, ~w(spec replicas)) %></:col>
      <:col :let={stateful_set} label="Available">
        <%= get_in(stateful_set, ~w(status availableReplicas)) %>
      </:col>

      <:action :let={stateful_set}>
        <.link navigate={resource_show_url(stateful_set)} type="styled">
          Show Stateful Set
        </.link>
      </:action>
    </.table>
    """
  end
end
