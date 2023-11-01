defmodule ControlServerWeb.ServicesTable do
  @moduledoc false
  use ControlServerWeb, :html

  import ControlServerWeb.ResourceURL

  alias ControlServerWeb.Resource

  attr :services, :list, required: true
  attr :id, :string, default: "services_table"

  def services_table(assigns) do
    ~H"""
    <.table rows={@services} id={@id} row_click={&JS.navigate(resource_show_path(&1))}>
      <:col :let={service} label="Name"><%= Resource.name(service) %></:col>
      <:col :let={service} label="Namespace"><%= Resource.namespace(service) %></:col>
      <:col :let={service} label="Cluster IP"><%= get_in(service, ~w(spec clusterIP)) %></:col>
      <:col :let={service} label="Ports"><%= ports(service) %></:col>

      <:action :let={service}>
        <.action_icon
          to={resource_show_path(service)}
          icon={:eye}
          tooltip="Show Service"
          id={"show_service_" <> Resource.id(service)}
        />
      </:action>
    </.table>
    """
  end

  defp ports(service) do
    service
    |> Map.get("spec", %{})
    |> Map.get("ports", [])
    |> Enum.map_join(", ", fn p -> Map.get(p, "port", 0) end)
  end
end
