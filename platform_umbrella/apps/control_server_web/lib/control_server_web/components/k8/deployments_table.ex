defmodule ControlServerWeb.DeploymentsTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  def deployments_table(assigns) do
    ~H"""
    <.table
      rows={@deployments || []}
      row_click={&JS.navigate(resource_path(&1))}
      id="deployments_table"
    >
      <:col :let={deployment} label="Name"><%= name(deployment) %></:col>
      <:col :let={deployment} label="Namespace"><%= namespace(deployment) %></:col>
      <:col :let={deployment} label="Replicas"><%= replicas(deployment) %></:col>
      <:col :let={deployment} label="Available"><%= available_replicas(deployment) %></:col>

      <:action :let={deployment}>
        <.flex>
          <.button
            variant="minimal"
            link={resource_path(deployment)}
            icon={:eye}
            id={"deployment_show_link_" <> to_html_id(deployment)}
          />
          <.tooltip target_id={"deployment_show_link_" <> to_html_id(deployment)}>
            Show Deployment
          </.tooltip>
        </.flex>
      </:action>
    </.table>

    <.light_text :if={@deployments == []}>No deployments available</.light_text>
    """
  end
end
