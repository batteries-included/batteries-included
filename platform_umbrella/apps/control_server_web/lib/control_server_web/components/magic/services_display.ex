defmodule ControlServerWeb.ServicesDisplay do
  use ControlServerWeb, :component

  import ControlServerWeb.ResourceURL
  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  attr :services, :list, required: true

  def services_display(assigns) do
    ~H"""
    <.table id="service-display-table" rows={@services}>
      <:col :let={service} label="Namespace"><%= namespace(service) %></:col>
      <:col :let={service} label="Name"><%= name(service) %></:col>
      <:col :let={service} label="Cluster IP"><%= get_in(service, ~w(spec clusterIP)) %></:col>
      <:col :let={service} label="Ports"><%= ports(service) %></:col>

      <:action :let={service}>
        <.link navigate={resource_show_url(service)} type="styled">
          Show service
        </.link>
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
