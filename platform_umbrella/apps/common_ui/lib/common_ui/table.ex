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
  attr :transparent, :boolean, default: false

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    ~H"""
    <div class="px-4 overflow-auto sm:px-0">
      <PC.table id={@id}>
        <thead>
          <PC.tr class={maybe_transparent_class(@transparent)}>
            <PC.th :for={col <- @col} class={maybe_transparent_class(@transparent)}>
              <%= col[:label] %>
            </PC.th>
            <PC.th :if={@action != nil && @action != []}>
              <span class="sr-only">Actions</span>
            </PC.th>
          </PC.tr>
        </thead>
        <tbody>
          <PC.tr
            :for={{row, idx} <- Enum.with_index(@rows)}
            id={to_row_id(@id, row, idx)}
            class={["group", maybe_transparent_class(@transparent)]}
          >
            <PC.td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={[@row_click && "hover:cursor-pointer", maybe_transparent_class(@transparent)]}
            >
              <%= render_slot(col, row) %>
            </PC.td>
            <PC.td :if={@action != []} class="w-24">
              <div class="items-center justify-end hidden gap-2 group-hover:flex">
                <%= for action <- @action do %>
                  <%= render_slot(action, row) %>
                <% end %>
              </div>
            </PC.td>
          </PC.tr>
        </tbody>
      </PC.table>
    </div>
    """
  end

  # The bang is needed to override Petal Components default background.
  defp maybe_transparent_class(true), do: "!bg-transparent"
  defp maybe_transparent_class(false), do: ""

  defp to_row_id(parent_id, %{id: _} = row, _idx) when is_struct(row), do: "#{parent_id}-#{Phoenix.Param.to_param(row)}"
  defp to_row_id(parent_id, _row, idx), do: "#{parent_id}-idx-#{idx}"
end
