defmodule ControlServerWeb.FerretServicesTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonUI.Table

  defp show_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/show"
  defp edit_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/edit"

  attr :rows, :list, default: []
  attr :abbridged, :boolean, default: false

  def ferret_services_table(assigns) do
    ~H"""
    <.table
      id="ferret_services"
      rows={@rows}
      row_click={fn {_id, ferret_service} -> ferret_service |> show_url |> JS.navigate() end}
    >
      <:col :let={{_id, ferret_service}} label="Name"><%= ferret_service.name %></:col>
      <:col :let={{_id, ferret_service}} label="Instances">
        <%= ferret_service.instances %>
      </:col>
      <:col :let={{_id, ferret_service}} :if={!@abbridged} label="Cpu requested">
        <%= ferret_service.cpu_requested %>
      </:col>
      <:col :let={{_id, ferret_service}} :if={!@abbridged} label="Memory requested">
        <%= ferret_service.memory_requested %>
      </:col>
      <:action :let={{_id, ferret_service}}>
        <.flex class="justify-items-center align-middle">
          <.action_icon
            to={show_url(ferret_service)}
            icon={:eye}
            tooltip={"Show FerretDB Service " <> ferret_service.name}
            id={"show_ferret_service_" <> ferret_service.id}
          />
          <.action_icon
            to={edit_url(ferret_service)}
            icon={:pencil}
            tooltip={"Edit FerretDB Service " <> ferret_service.name}
            id={"edit_pool_" <> ferret_service.id}
          />
        </.flex>
      </:action>
    </.table>
    """
  end
end
