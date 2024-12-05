defmodule ControlServerWeb.FerretServicesTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :rows, :list, default: []
  attr :meta, :map, default: nil
  attr :abridged, :boolean, default: false

  def ferret_services_table(assigns) do
    ~H"""
    <.table
      id="ferret_services"
      variant={@meta && "paginated"}
      rows={@rows}
      meta={@meta}
      path={~p"/ferretdb"}
      row_click={&JS.navigate(show_url(&1))}
    >
      <:col :let={service} :if={!@abridged} field={:id} label="ID">{service.id}</:col>
      <:col :let={service} field={:name} label="Name">{service.name}</:col>
      <:col :let={service} :if={!@abridged} field={:instances} label="Instances">
        {service.instances}
      </:col>
      <:action :let={service}>
        <.flex class="justify-items-center align-middle">
          <.button
            variant="minimal"
            link={edit_url(service)}
            icon={:pencil}
            id={"edit_service_" <> service.id}
          />

          <.tooltip target_id={"edit_service_" <> service.id}>
            Edit FerretDB Service
          </.tooltip>

          <.button
            variant="minimal"
            link={show_url(service)}
            icon={:eye}
            id={"service_show_link_" <> service.id}
          />
          <.tooltip target_id={"service_show_link_" <> service.id}>
            Show FerretDB Service
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(service), do: ~p"/ferretdb/#{service}/show"
  defp edit_url(service), do: ~p"/ferretdb/#{service}/edit"
end
