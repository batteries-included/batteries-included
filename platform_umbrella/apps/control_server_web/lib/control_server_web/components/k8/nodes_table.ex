defmodule ControlServerWeb.NodesTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors

  def nodes_table(assigns) do
    ~H"""
    <.table rows={@nodes || []} id="nodes_table">
      <:col :let={node} label="Name">{name(node)}</:col>
      <:col :let={node} label="CPU">{get_in(node, ~w(status capacity cpu))}</:col>
      <:col :let={node} label="Memory">{get_in(node, ~w(status capacity memory))}</:col>
      <:col :let={node} label="Kernel">{get_in(node, ~w(status nodeInfo kernelVersion))}</:col>
      <:col :let={node} label="Kube">{get_in(node, ~w(status nodeInfo kubeletVersion))}</:col>
    </.table>

    <.light_text :if={@nodes == []}>No nodes available</.light_text>
    """
  end
end
