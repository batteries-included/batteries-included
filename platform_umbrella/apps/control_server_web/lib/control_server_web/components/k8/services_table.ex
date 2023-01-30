defmodule ControlServerWeb.ServicesTable do
  use ControlServerWeb, :html

  import ControlServerWeb.ResourceURL
  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  attr :services, :list, required: true
  attr :id, :string, default: "services_table"

  def services_table(assigns) do
    ~H"""
    <.table rows={@services} id={@id}>
      <:col :let={service} label="Name"><%= name(service) %></:col>
      <:col :let={service} label="Namespace"><%= namespace(service) %></:col>
      <:col :let={service} label="Cluster IP"><%= get_in(service, ~w(spec clusterIP)) %></:col>
      <:col :let={service} label="Ports"><%= ports(service) %></:col>

      <:action :let={service}>
        <.link navigate={resource_show_url(service)} variant="styled">
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
