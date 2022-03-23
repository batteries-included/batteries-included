defmodule ControlServerWeb.Live.KnativeServicesIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Knative

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :services, list_services())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Services")
    |> assign(:service, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    service = Knative.get_service!(id)
    {:ok, _} = Knative.delete_service(service)

    {:noreply, assign(socket, :services, list_services())}
  end

  defp list_services do
    Knative.list_services()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>KNative Services</.title>
      </:title>
      <:left_menu>
        <.left_menu_item to="/services/devtools/tools" name="Tools" icon="external_link" />
        <.left_menu_item
          to="/services/devtools/settings"
          name="Service Settings"
          icon="lightning_bolt"
        />
        <.left_menu_item to="/services/devtools/knative_services" name="Services" icon="collection" />
        <.left_menu_item to="/services/devtools/status" name="Status" icon="status_online" />
      </:left_menu>
      <.body_section>
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th></th>
            </tr>
          </thead>
          <tbody id="services">
            <%= for service <- @services do %>
              <tr id={"service-#{service.id}"}>
                <td><%= service.name %></td>
                <td>
                  <span>
                    <%= link("Delete",
                      to: "#",
                      phx_click: "delete",
                      phx_value_id: service.id,
                      data: [confirm: "Are you sure?"]
                    ) %>
                  </span>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </.body_section>
    </.layout>
    """
  end
end
