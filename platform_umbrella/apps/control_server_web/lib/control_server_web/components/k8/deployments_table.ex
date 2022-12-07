defmodule ControlServerWeb.DeploymentsTable do
  use ControlServerWeb, :html

  import ControlServerWeb.ResourceURL
  import K8s.Resource.FieldAccessors

  def deployments_table(assigns) do
    ~H"""
    <.table rows={@deployments}>
      <:col :let={deployment} label="Namespace"><%= namespace(deployment) %></:col>
      <:col :let={deployment} label="Name"><%= name(deployment) %></:col>
      <:col :let={deployment} label="Replicas"><%= get_in(deployment, ~w(spec replicas)) %></:col>
      <:col :let={deployment} label="Available">
        <%= get_in(deployment, ~w(status availableReplicas)) %>
      </:col>

      <:action :let={deployment}>
        <.link navigate={resource_show_url(deployment)} variant="styled">
          Show Deployment
        </.link>
      </:action>
    </.table>
    """
  end
end
