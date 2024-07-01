defmodule ControlServerWeb.BackendServicesTable do
  @moduledoc false

  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Backend.Service

  attr :rows, :list, required: true
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def backend_services_table(assigns) do
    ~H"""
    <.table id="backend-display-table" rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={service} :if={!@abbridged} label="ID"><%= service.id %></:col>
      <:col :let={service} label="Name"><%= service.name %></:col>
      <:action :let={service}>
        <.flex class="justify-items-center">
          <.button
            variant="minimal"
            link={show_url(service)}
            icon={:eye}
            id={"show_service_" <> service.id}
          />

          <.tooltip target_id={"show_service_" <> service.id}>
            Show Service <%= service.name %>
          </.tooltip>

          <.button
            variant="minimal"
            link={service_url(service)}
            link_type="external"
            target="_blank"
            icon={:arrow_top_right_on_square}
            id={"running_service_" <> service.id}
          />

          <.tooltip target_id={"running_service_" <> service.id}>
            Running Service
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(%Service{} = service), do: ~p"/backend/services/#{service}/show"
  defp service_url(%Service{} = service), do: "//#{backend_host(service)}"
end
