defmodule CommonUI.Card do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Typogoraphy

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id)

  slot :inner_block
  slot :title

  def card(assigns) do
    ~H"""
    <div
      class={
        build_class([
          "p-4 bg-white rounded-lg border border-gray-200 shadow-lg",
          "flex flex-col",
          @class
        ])
      }
      {@rest}
    >
      <.h2 :if={@title != nil and @title != []}>
        <%= render_slot(@title) %>
      </.h2>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :no_body_padding, :boolean, default: false
  attr :rest, :global, include: ~w(id)

  slot :inner_block
  slot :top_right
  slot :title

  @doc """
  This is like card but updated with the new design.
  """
  def panel(assigns) do
    ~H"""
    <div
      class={
        build_class([
          "bg-white border border-gray-300 rounded-lg dark:bg-gray-900 dark:border-gray-600",
          @class
        ])
      }
      {@rest}
    >
      <div :if={render_slot(@title)} class="flex items-center justify-between w-full p-6 text-center">
        <PC.h3>
          <%= render_slot(@title) %>
        </PC.h3>
        <%= if render_slot(@top_right) do %>
          <%= render_slot(@top_right) %>
        <% end %>
      </div>

      <div class={panel_body_class(@no_body_padding, @title)}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp panel_body_class(true, _title), do: ""
  defp panel_body_class(false, []), do: "p-6"
  defp panel_body_class(false, _title), do: "px-6 pb-6"

  attr :rest, :global
  attr :label, :string

  def new_button(assigns) do
    ~H"""
    <div class="flex group text-primary-500 hover:text-primary-700 group-hover:fill-primary-700">
      <button type="button" {@rest} class="flex items-center gap-2">
        <Heroicons.plus class="w-4 h-4 stroke-[3] fill-primary-500" />
        <p class="text-base "><%= @label %></p>
      </button>
    </div>
    """
  end
end
