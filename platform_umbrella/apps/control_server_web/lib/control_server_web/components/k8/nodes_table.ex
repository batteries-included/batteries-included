defmodule ControlServerWeb.NodesTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  def nodes_table(assigns) do
    ~H"""
    <.table rows={@nodes || []} id="nodes_table" row_click={&JS.navigate(resource_path(&1))}>
      <:col :let={node} label="Name">{name(node)}</:col>
      <:col :let={node} label="CPU">{get_in(node, ~w(status capacity cpu))}</:col>
      <:col :let={node} label="Memory">{get_in(node, ~w(status capacity memory))}</:col>
      <:col :let={node} label="Kernel">{get_in(node, ~w(status nodeInfo kernelVersion))}</:col>
      <:col :let={node} label="Kube">{get_in(node, ~w(status nodeInfo kubeletVersion))}</:col>

      <:action :let={node}>
        <.flex>
          <.button
            variant="minimal"
            link={resource_path(node)}
            icon={:eye}
            id={"node_show_link_" <> to_html_id(node)}
          />
          <.tooltip target_id={"node_show_link_" <> to_html_id(node)}>
            Show Node
          </.tooltip>
        </.flex>
      </:action>
    </.table>

    <.light_text :if={@nodes == []}>No nodes available</.light_text>
    """
  end
end
