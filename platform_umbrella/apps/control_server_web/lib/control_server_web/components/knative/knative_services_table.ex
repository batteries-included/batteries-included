defmodule ControlServerWeb.KnativeServicesTable do
  use ControlServerWeb, :html

  alias KubeResources.KnativeServing, as: KnativeResources
  alias ControlServer.Knative

  attr :knative_services, :list, required: true

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

  defp service_url(%Knative.Service{} = service), do: KnativeResources.url(service)
end
