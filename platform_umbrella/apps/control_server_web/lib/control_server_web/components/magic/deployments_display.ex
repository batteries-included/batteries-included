defmodule ControlServerWeb.DeploymentsDisplay do
  use ControlServerWeb, :component

  import ControlServerWeb.ResourceURL
  import K8s.Resource.FieldAccessors

  def deployments_display(assigns) do
    ~H"""
    <.table id="deployment-display-table" rows={@deployments}>
      <:col :let={deployment} label="Namespace"><%= namespace(deployment) %></:col>
      <:col :let={deployment} label="Name"><%= name(deployment) %></:col>
      <:col :let={deployment} label="Replicas"><%= get_in(deployment, ~w(spec replicas)) %></:col>
      <:col :let={deployment} label="Available">
        <%= get_in(deployment, ~w(spec availableReplics)) %>
      </:col>

      <:action :let={deployment}>
        <.link navigate={resource_show_url(deployment)} type="styled">
          Show Deployment
        </.link>
      </:action>
    </.table>
    """
  end
end
