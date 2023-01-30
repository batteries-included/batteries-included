defmodule CommonUI.Table do
  use Phoenix.Component

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, default: nil
  attr :row_click, :any, default: nil
  attr :rows, :list, required: true

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    ~H"""
    <div id={@id} class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="mt-4 w-full">
        <thead class="text-left text-base leading-6 text-gray-700">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 text-pink-500">
              <%= col[:label] %>
            </th>
            <th :if={@action != nil && @action != []} class="relative p-0 pb-4">
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody class="relative divide-y divide-gray-100 border-t border-gray-200 text-sm leading-6 text-gray-700">
          <tr
            :for={{row, idx} <- Enum.with_index(@rows)}
            id={to_row_id(@id, row, idx)}
            class="relative group hover:bg-gray-50"
          >
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div :if={i == 0}>
                <span class="absolute h-full w-4 top-0 -left-4 group-hover:bg-gray-50 sm:rounded-l-xl" />
                <span class="absolute h-full w-4 top-0 -right-4 group-hover:bg-gray-50 sm:rounded-r-xl" />
              </div>
              <div class="block py-4 pr-6">
                <span class={["relative", i == 0 && "font-semibold text-gray-900"]}>
                  <%= render_slot(col, row) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="p-0 w-14">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-gray-900 hover:text-gray-700"
                >
                  <%= render_slot(action, row) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp to_row_id(parent_id, %{id: _} = row, _idx),
    do: "#{parent_id}-#{Phoenix.Param.to_param(row)}"

  defp to_row_id(parent_id, _row, idx), do: "#{parent_id}-idx-#{idx}"
end
