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
          Running Service
        </.a>
      </:col>
      <:action :let={service}>
        <.action_icon
          to={show_url(service)}
          icon={:eye}
          tooltip={"Show Service " <> service.name}
          id={"show_service_" <> service.id}
        />
      </:action>
    </.table>
    """
  end

  defp show_url(%Service{} = service), do: ~p"/knative/services/#{service.id}/show"

  defp service_url(%Service{} = service), do: "//#{knative_host(service)}"
end
