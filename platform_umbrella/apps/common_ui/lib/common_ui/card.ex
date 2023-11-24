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
  attr :no_body_padding, :boolean, default: false
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
        :if={@title || @inner_block}
        class="items-center justify-between w-full p-6 text-center flex-col lg:flex-row"
      >
        <.h3 :if={@title}><%= @title %></.h3>

        <%= if @menu do %>
          <%= render_slot(@menu) %>
        <% end %>
      </.flex>

      <div class={panel_body_class(@no_body_padding, @title)}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp get_classes("simple"), do: "bg-white border border-gray-200 rounded-lg dark:bg-gray-900 dark:border-gray-600"

  defp get_classes("gray"), do: "bg-gray-50 rounded-lg dark:bg-gray-800"

  defp panel_body_class(true, _title), do: "overflow-x-auto"
  defp panel_body_class(false, nil), do: "p-6 overflow-x-auto"
  defp panel_body_class(false, _title), do: "px-6 pb-6 overflow-x-auto"
end
