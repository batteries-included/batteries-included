defmodule CommonUI.Components.Table do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Container

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
      <table class="w-[40rem] mt-4 sm:w-full">
        <thead class="text-sm text-left leading-6 text-gray-darker dark:text-gray">
          <tr>
            <th :for={col <- @col} class="p-0 pb-4 font-normal"><%= col[:label] %></th>
            <th :if={@action && @action != []} class="p-0 pb-4">
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="relative border-t border-gray-lighter dark:border-gray-darker text-sm leading-6 text-gray-darkest dark:text-gray-lighter"
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class={[
              "group",
              @row_click && "hover:bg-gray-lightest dark:hover:bg-gray-darkest"
            ]}
          >
            <td
              :for={{col, i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class={["p-0 px-2 align-top", @row_click && "hover:cursor-pointer"]}
            >
              <div class="block py-4">
                <span class={[i == 0 && "font-semibold text-gray-darkest dark:text-gray-lightest"]}>
                  <%= render_slot(col, @row_item.(row)) %>
                </span>
              </div>
            </td>
            <td :if={@action} class="w-14 p-0">
              <.flex class="whitespace-nowrap text-sm font-medium justify-around">
                <div
                  :for={action <- @action}
                  class="font-semibold leading-6 text-gray-darkest dark:text-gray-lightest p-4"
                >
                  <%= render_slot(action, @row_item.(row)) %>
                </div>
              </.flex>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end
end
