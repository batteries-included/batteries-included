defmodule ControlServerWeb.BackendServicesTable do
  @moduledoc false

  use ControlServerWeb, :html

  alias CommonCore.Backend.Service

  attr :rows, :list, required: true
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def backend_services_table(assigns) do
    ~H"""
    <.table id="backend-display-table" rows={@rows}>
      <:col :let={service} :if={!@abbridged} label="ID"><%= service.id %></:col>
      <:col :let={service} label="Name"><%= service.name %></:col>
      <:action :let={service}>
        <.button
          variant="minimal"
          link={show_url(service)}
          icon={:eye}
          id={"show_service_" <> service.id}
        />

        <.tooltip target_id={"show_service_" <> service.id}>
          Show Service <%= service.name %>
        </.tooltip>
      </:action>
    </.table>
    """
  end

  defp show_url(%Service{} = service), do: "/backend_services/#{service.id}/show"
end
