defmodule ControlServerWeb.PodDisplay do
  use Phoenix.Component

  use PetalComponents

  def pods_display(assigns) do
    ~H"""
    <.h3>
      Pods
    </.h3>
    <table class="min-w-full divide-y divide-gray-200">
      <thead>
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
        <%= for pod <- @pods do %>
          <.pod_row pod={pod} />
        <% end %>
      </tbody>
    </table>
    """
  end

  defp pod_row(assigns) do
    ~H"""
    <tr class={["bg-white"]}>
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
