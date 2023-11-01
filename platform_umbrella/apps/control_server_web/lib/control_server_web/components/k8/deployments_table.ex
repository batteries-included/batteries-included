defmodule ControlServerWeb.DeploymentsTable do
  @moduledoc false
  use ControlServerWeb, :html

  import ControlServerWeb.ResourceURL

  alias ControlServerWeb.Resource

  def deployments_table(assigns) do
    ~H"""
    <.table
      :if={@deployments != []}
      rows={@deployments}
      row_click={&JS.navigate(resource_show_path(&1))}
    >
      <:col :let={deployment} label="Name"><%= Resource.name(deployment) %></:col>
      <:col :let={deployment} label="Namespace"><%= Resource.namespace(deployment) %></:col>
      <:col :let={deployment} label="Replicas"><%= get_in(deployment, ~w(spec replicas)) %></:col>
      <:col :let={deployment} label="Available">
        <%= get_in(deployment, ~w(status availableReplicas)) %>
      </:col>

      <:action :let={deployment}>
        <.action_icon
          to={resource_show_path(deployment)}
          icon={:eye}
          id={"show_deployment_" <> Resource.id(deployment)}
          tooltip="Show Deployment"
        />
      </:action>
    </.table>

    <.light_text :if={@deployments == []}>No deployments available</.light_text>
    """
  end
end
