defmodule ControlServerWeb.NodesTable do
  @moduledoc false
  use ControlServerWeb, :html

  alias ControlServerWeb.Resource

  def nodes_table(assigns) do
    ~H"""
    <.table :if={@nodes != []} rows={@nodes}>
      <:col :let={node} label="Name"><%= Resource.name(node) %></:col>
      <:col :let={node} label="CPU"><%= get_in(node, ~w(status capacity cpu)) %></:col>
      <:col :let={node} label="Memory"><%= get_in(node, ~w(status capacity memory)) %></:col>
      <:col :let={node} label="Kernel"><%= get_in(node, ~w(status nodeInfo kernelVersion)) %></:col>
      <:col :let={node} label="Kube"><%= get_in(node, ~w(status nodeInfo kubeletVersion)) %></:col>
    </.table>

    <.light_text :if={@nodes == []}>No nodes available</.light_text>
    """
  end
end
