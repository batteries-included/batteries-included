defmodule ControlServerWeb.Keycloak.ClientsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :clients, :list, required: true

  def keycloak_clients_table(%{} = assigns) do
    ~H"""
    <.table id="keycloak-clients-table" rows={@clients}>
      <:col :let={client} label="Client Id">{client.clientId}</:col>
      <:col :let={client} label="Name">{client.name}</:col>
      <:col :let={client} label="Url">{client.baseUrl}</:col>
      <:col :let={client} label="Enabled">{client.enabled}</:col>
    </.table>
    """
  end
end
