defmodule CommonUI.Table do
  @moduledoc false
  use CommonUI.Component

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: false, default: nil, doc: "the id of the table"
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-y-auto px-4 sm:overflow-visible sm:px-0">
      <table class="w-[40rem] mt-11 sm:w-full">
        <thead class="text-sm text-left leading-6 text-gray-600 dark:text-gray-400">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 pr-6 font-normal"><%= col[:label] %></th>
            <th :if={@action != []} class="relative p-0 pb-4">
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative dark:divide-y dark:divide-gray-0 border-t border-gray-200 dark:border-gray-800 text-sm leading-6 text-gray-700 dark:text-gray-200"
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class={["group", @row_click && "hover:bg-gray-50 dark:hover:bg-gray-800"]}
          >
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["relative p-0", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4 pr-6">
                <span class={[
                  "absolute -inset-y-px right-0 -left-4 sm:rounded-l-xl",
                  @row_click && "group-hover:bg-gray-50 dark:group-hover:bg-gray-800"
                ]} />
                <span class={["relative", i == 0 && "font-semibold text-gray-900 dark:text-gray-100"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action != []} class="relative w-14 p-0">
              <div class="relative whitespace-nowrap py-4 text-right text-sm font-medium">
                <span class={[
                  "absolute -inset-y-px -right-4 left-0 sm:rounded-r-xl",
                  @row_click && "group-hover:bg-gray-50 dark:group-hover:bg-gray-800"
                ]} />
                <span
                  :for={action <- @action}
                  class="relative ml-4 font-semibold leading-6 text-gray-900 dark:text-gray-100"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </span>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
