defmodule CommonUI.Page do
  @moduledoc false
  use CommonUI.Component

  attr :title, :string

  attr :back_button, :map,
    default: nil,
    doc: ~s|Attributes for the back link, if it exists. eg. back_button={%{link_type="live_redirect" to="/"}}|

  slot :right_side

  def page_header(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center gap-4">
        <PC.a
          :if={@back_button}
          {@back_button}
          class="inline-block p-1.5 border border-gray-300 rounded-lg border-1 dark:border-gray-600"
        >
          <Heroicons.arrow_left class="w-4 h-4 stroke-[3] text-primary-500 fill-primary-500 dark:text-primary-300 dark:fill-primary-300" />
        </PC.a>
        <div class="flex items-center gap-3">
          <h3 class="text-2xl font-medium text-black dark:text-white">
            <%= @title %>
          </h3>
        </div>
      </div>

      <%= if render_slot(@right_side) do %>
        <%= render_slot(@right_side) %>
      <% end %>
    </div>
    """
  end
end
