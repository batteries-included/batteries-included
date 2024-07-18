defmodule ControlServerWeb.TraditionalServicesTable do
  @moduledoc false

  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.TraditionalServices.Service

  attr :rows, :list, required: true
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def traditional_services_table(assigns) do
    ~H"""
    <.table id="traditional-display-table" rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={service} :if={!@abridged} label="ID"><%= service.id %></:col>
      <:col :let={service} label="Name"><%= service.name %></:col>
      <:col :let={service} :if={!@abridged} label="Instances"><%= service.num_instances %></:col>
      <:action :let={service}>
        <.flex class="justify-items-center">
          <.button
            variant="minimal"
            link={edit_url(service)}
            icon={:pencil}
            id={"edit_service_" <> service.id}
          />

          <.tooltip target_id={"edit_service_" <> service.id}>
            Edit Traditional Service
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
            Open Traditional Service
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(%Service{} = service), do: ~p"/traditional_services/#{service}/show"
  defp edit_url(%Service{} = service), do: ~p"/traditional_services/#{service}/edit"
  defp service_url(%Service{} = service), do: "//#{traditional_host(service)}"
end
