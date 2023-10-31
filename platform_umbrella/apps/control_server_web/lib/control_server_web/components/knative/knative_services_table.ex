defmodule ControlServerWeb.KnativeServicesTable do
  @moduledoc false
  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Knative.Service

  attr :rows, :list, required: true
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def knative_services_table(assigns) do
    ~H"""
    <.table id="knative-display-table" rows={@rows}>
      <:col :let={service} :if={!@abbridged} label="ID"><%= service.id %></:col>
      <:col :let={service} label="Name"><%= service.name %></:col>
      <:col :let={service} label="Link">
        <.a href={service_url(service)} variant="external">
          <%= service_url(service) %>
        </.a>
      </:col>
      <:action :let={service}>
        <.a navigate={~p"/knative/services/#{service}/show"}>Show Service</.a>
      </:action>
    </.table>
    """
  end

  defp service_url(%Service{} = service), do: "http://#{knative_host(service)}"
end
