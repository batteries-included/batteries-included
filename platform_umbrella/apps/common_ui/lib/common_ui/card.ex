defmodule CommonUI.Card do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Container
  import CommonUI.Typography

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(id)

  slot :inner_block
  slot :title

  def card(assigns) do
    ~H"""
    <div
      class={[
        "p-4 bg-white rounded-lg border border-gray-200 shadow-lg",
        "flex flex-col",
        @class
      ]}
      {@rest}
    >
      <.h2 :if={@title != nil and @title != []}>
        <%= render_slot(@title) %>
      </.h2>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :title, :string, default: nil
  attr :class, :string, default: nil
  attr :variant, :string, default: "simple", values: ["simple", "gray"]
  attr :rest, :global, include: ~w(id)

  slot :inner_block
  slot :menu

  @doc """
  This is like card but updated with the new design.
  """
  def panel(assigns) do
    ~H"""
    <div class={[get_classes(@variant), @class]} {@rest}>
      <.flex
        :if={@title != nil && @title != ""}
        class="items-center justify-between w-full p-4 text-center flex-col lg:flex-row"
      >
        <.h3 :if={@title}><%= @title %></.h3>

        <%= if @menu do %>
          <%= render_slot(@menu) %>
        <% end %>
      </.flex>

      <div class="p-4">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp get_classes("simple"), do: "bg-white border border-gray-200 rounded-lg dark:bg-gray-900/70 dark:border-gray-600"

  defp get_classes("gray"), do: "bg-gray-50 rounded-lg dark:bg-gray-700/50"
end
