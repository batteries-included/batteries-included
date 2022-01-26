defmodule ControlServerWeb.PodDisplay do
  use Phoenix.Component

  import CommonUI.ShadowContainer

  def pods_display(assigns) do
    ~H"""
    <h3 class="mt-2 text-lg leading-7 sm:text-3xl sm:truncate">
      Pods
    </h3>
    <.shadow_container>
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-100">
          <tr>
            <th
              scope="col"
              class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
            >
              Name
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
            >
              Status
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
            >
              Restarts
            </th>
            <th
              scope="col"
              class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
            >
              Age
            </th>
          </tr>
        </thead>
        <tbody>
          <%= for {pod, _idx} <- Enum.with_index(@pods) do %>
            <.pod_row pod={pod} />
          <% end %>
        </tbody>
      </table>
    </.shadow_container>
    """
  end

  defp pod_row(assigns) do
    ~H"""
    <tr class={["bg-white", "bg-gray-100"]}>
      <td class="px-6 py-4 text-sm font-medium text-gray-900 whitespace-nowrap">
        <%= @pod["metadata"]["name"] %>
      </td>
      <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
        <%= @pod["status"]["phase"] %>
      </td>
      <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
        <%= @pod["summary"]["restartCount"] %>
      </td>
      <td class="px-6 py-4 text-sm text-gray-500 whitespace-nowrap">
        <%= @pod["summary"]["fromStart"] %>
      </td>
    </tr>
    """
  end
end
