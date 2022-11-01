defmodule ControlServerWeb.NodesDisplay do
  use ControlServerWeb, :html

  import K8s.Resource.FieldAccessors, only: [name: 1]

  def nodes_display(assigns) do
    ~H"""
    <.table id="node-display-table" rows={@nodes}>
      <:col :let={node} label="Name"><%= name(node) %></:col>
      <:col :let={node} label="CPU"><%= get_in(node, ~w(status capacity cpu)) %></:col>
      <:col :let={node} label="Memory"><%= get_in(node, ~w(status capacity memory)) %></:col>
      <:col :let={node} label="Kernel"><%= get_in(node, ~w(status nodeInfo kernelVersion)) %></:col>
      <:col :let={node} label="Kube"><%= get_in(node, ~w(status nodeInfo kubeletVersion)) %></:col>
    </.table>
    """
  end
end
