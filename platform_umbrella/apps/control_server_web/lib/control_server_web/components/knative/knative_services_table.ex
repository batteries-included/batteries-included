defmodule ControlServerWeb.KnativeServicesTable do
  use ControlServerWeb, :html
  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Knative.Service

  attr :knative_services, :list, required: true

  def knative_services_table(assigns) do
    ~H"""
    <.table id="knative-display-table" rows={@knative_services}>
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
