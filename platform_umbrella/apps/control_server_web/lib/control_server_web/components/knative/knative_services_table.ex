defmodule ControlServerWeb.KnativeServicesTable do
  @moduledoc false
  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Knative.Service

  attr :rows, :list, required: true
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def knative_services_table(assigns) do
    ~H"""
    <.table id="knative-display-table" rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={service} :if={!@abridged} label="ID"><%= service.id %></:col>
      <:col :let={service} label="Name"><%= service.name %></:col>
      <:col :let={service} :if={!@abridged} label="Rollout Duration">
        <%= service.rollout_duration %>
      </:col>
      <:action :let={service}>
        <.flex class="justify-items-center">
          <.button
            variant="minimal"
            link={edit_url(service)}
            icon={:pencil}
            id={"edit_service_" <> service.id}
          />

          <.tooltip target_id={"edit_service_" <> service.id}>
            Edit Knative Service
          </.tooltip>

          <.button
            variant="minimal"
            link={service_url(service)}
            link_type="external"
            target="_blank"
            icon={:arrow_top_right_on_square}
            id={"open_service_" <> service.id}
          />

          <.tooltip target_id={"open_service_" <> service.id}>
            Open Knative Service
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(%Service{} = service), do: ~p"/knative/services/#{service.id}/show"
  defp edit_url(%Service{} = service), do: ~p"/knative/services/#{service.id}/edit"
  defp service_url(%Service{} = service), do: "http://#{knative_host(service)}"
end
