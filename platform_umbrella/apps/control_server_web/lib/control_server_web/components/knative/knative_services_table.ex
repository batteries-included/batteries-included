defmodule ControlServerWeb.KnativeServicesTable do
  use ControlServerWeb, :html

  alias CommonCore.Knative.Service

  alias KubeResources.KnativeServing, as: KnativeResources

  attr(:knative_services, :list, required: true)

  def knative_services_table(assigns) do
    ~H"""
    <.table id="knative-display-table" rows={@knative_services}>
      <:col :let={service} label="Name"><%= service.name %></:col>
      <:col :let={service} label="Link">
        <.link href={service_url(service)} variant="external">
          <%= service_url(service) %>
        </.link>
      </:col>
      <:action :let={service}>
        <.link navigate={~p"/knative/services/#{service}/show"}>Show Service</.link>
      </:action>
    </.table>
    """
  end

  defp service_url(%Service{} = service), do: KnativeResources.url(service)
end
