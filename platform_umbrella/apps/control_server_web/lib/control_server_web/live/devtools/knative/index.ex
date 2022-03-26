defmodule ControlServerWeb.Live.KnativeServicesIndex do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import CommonUI.Table

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
        <.title>Knative Services</.title>
      </:title>
      <:left_menu>
        <.devtools_menu active="knative" />
      </:left_menu>
      <.body_section>
        <.table>
          <.thead>
            <.tr>
              <.th>Name</.th>
              <.th>Link</.th>
              <.th>Action</.th>
            </.tr>
          </.thead>
          <.tbody id="services">
            <%= for service <- @services do %>
              <.tr id={"service-#{service.id}"}>
                <.td><%= service.name %></.td>
                <.td>
                  <.link
                    to={"//#{service.name}.battery-knative.knative.172.30.0.4.sslip.io"}
                    link_type="a"
                  >
                    Open
                  </.link>
                </.td>
                <.td>
                  <span>
                    <%= link("Delete",
                      to: "#",
                      phx_click: "delete",
                      phx_value_id: service.id,
                      data: [confirm: "Are you sure?"]
                    ) %>
                  </span>

                  <span>
                    <.link to={service_edit_url(service)}>Edit</.link>
                  </span>
                </.td>
              </.tr>
            <% end %>
          </.tbody>
        </.table>

        <div class="ml-8 mt-15">
          <.button type="primary" variant="shadow" to={service_new_url()} link_type="live_patch">
            New Knative Service
          </.button>
        </div>
      </.body_section>
    </.layout>
    """
  end

  defp service_edit_url(service),
    do: Routes.knative_edit_path(ControlServerWeb.Endpoint, :edit, service.id)

  defp service_new_url do
    Routes.knative_new_path(ControlServerWeb.Endpoint, :new)
  end
end
