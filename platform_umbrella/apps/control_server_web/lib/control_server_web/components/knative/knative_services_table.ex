defmodule ControlServerWeb.KnativeServicesTable do
  @moduledoc false
  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryURLs

  alias CommonCore.Knative.Service

  attr :rows, :list, required: true
  attr :meta, :map, default: nil
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def knative_services_table(assigns) do
    ~H"""
    <.table
      id="knative-display-table"
      variant={@meta && "paginated"}
      rows={@rows}
      meta={@meta}
      path={~p"/knative/services"}
      row_click={&JS.navigate(show_url(&1))}
    >
      <:col :let={service} :if={!@abridged} field={:id} label="ID">{service.id}</:col>
      <:col :let={service} field={:name} label="Name">{service.name}</:col>
      <:col :let={service} :if={!@abridged} field={:rollout_duration} label="Rollout Duration">
        {service.rollout_duration}
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
            :if={!service.kube_internal}
            variant="minimal"
            link={service_url(service)}
            link_type="external"
            target="_blank"
            icon={:arrow_top_right_on_square}
            id={"open_service_" <> service.id}
          />

          <.tooltip :if={!service.kube_internal} target_id={"open_service_" <> service.id}>
            Open Knative Service
          </.tooltip>

          <.button
            variant="minimal"
            link={show_url(service)}
            icon={:eye}
            id={"knative_service_show_link_" <> service.id}
          />
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(%Service{} = service), do: ~p"/knative/services/#{service.id}/show"
  defp edit_url(%Service{} = service), do: ~p"/knative/services/#{service.id}/edit"
  defp service_url(%Service{} = service), do: knative_service_url(service)
end
