defmodule ControlServerWeb.BaseServiceStatusList do
  use ControlServerWeb, :live_component
  import CommonUI.ShadowContainer

  @impl true
  def mount(socket) do
    {:ok, assign_new(socket, :services, fn -> [] end)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, :services, update_services(assigns.services))}
  end

  defp update_services(services) when is_list(services) do
    ##
    # From a list of services we recheck if they are running and recreate the map of string service
    services
    |> Enum.map(&update_single_service/1)
    |> Enum.into(%{})
  end

  def update_single_service(%{module: mod} = _s) do
    update_single_service(mod)
  end

  def update_single_service(module) do
    {"#{module.path()}", %{module: module, active: module.active?()}}
  end

  @impl true
  def handle_event("start", %{"path" => path} = _payload, socket) do
    service_module = socket.assigns.services |> Map.get(path) |> Map.get(:module)
    service_module.activate!()

    {:noreply, assign(socket, :services, update_services(socket.assigns.services))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.shadow_container>
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-100">
            <tr>
              <th
                scope="col"
                class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
              >
                Service Type
              </th>
              <th
                scope="col"
                class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
              >
                Service Handler
              </th>
              <th
                scope="col"
                class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
              >
                Start
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for {_path, service_info} <- @services do %>
              <.table_row service_info={service_info} target={@myself} />
            <% end %>
          </tbody>
        </table>
      </.shadow_container>
    </div>
    """
  end

  def table_row(assigns) do
    ~H"""
    <tr class={["bg-white", "bg-gray-100"]}>
      <td class="px-6 py-4 text-sm font-medium text-gray-900 whitespace-nowrap">
        <%= @service_info.module.service_type() %>
      </td>
      <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
        <%= @service_info.module %>
      </td>
      <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
        <%= if not @service_info.active do %>
          <.button
            label={"Start Service"}
            phx-click={:start}
            phx-value-path={@service_info.module.path()}
            phx-target={@target}
          />
        <% end %>
      </td>
    </tr>
    """
  end
end
