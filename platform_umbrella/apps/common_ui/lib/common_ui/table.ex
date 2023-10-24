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
  attr :id, :string, default: nil
  attr :row_click, :any, default: nil
  attr :rows, :list, required: true

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    ~H"""
    <div id={@id} class="overflow-y-auto sm:overflow-visible px-2">
      <PC.table>
        <PC.tr>
          <PC.th :for={col <- @col}>
            <%= col[:label] %>
          </PC.th>
          <PC.th :if={@action != nil && @action != []}>
            <span class="sr-only">Actions</span>
          </PC.th>
        </PC.tr>
        <PC.tr :for={{row, idx} <- Enum.with_index(@rows)} id={to_row_id(@id, row, idx)}>
          <PC.td
            :for={col <- @col}
            phx-click={@row_click && @row_click.(row)}
            class={[@row_click && "hover:cursor-pointer"]}
          >
            <%= render_slot(col, row) %>
          </PC.td>
          <PC.td :if={@action != []} class="w-10 relative">
            <span :for={action <- @action} class="relative ml-4 font-semibold leading-6">
              <%= render_slot(action, row) %>
            </span>
          </PC.td>
        </PC.tr>
      </PC.table>
    </div>
    """
  end

  defp to_row_id(parent_id, %{id: _} = row, _idx) when is_struct(row), do: "#{parent_id}-#{Phoenix.Param.to_param(row)}"

  defp to_row_id(parent_id, _row, idx), do: "#{parent_id}-idx-#{idx}"
end
