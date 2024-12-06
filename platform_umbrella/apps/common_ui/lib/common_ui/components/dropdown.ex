defmodule CommonUI.Components.Dropdown do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon

  alias CommonUI.IDHelpers

  attr :id, :string
  attr :class, :any, default: nil

  slot :inner_block, required: true
  slot :trigger

  def dropdown(assigns) do
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <div class="relative z-40">
      <div class="cursor-pointer" phx-click={show_dropdown(@id, :slide_y)}>
        {render_slot(@trigger)}
      </div>

      <nav
        id={@id}
        role="navigation"
        phx-click-away={hide_dropdown(@id, :slide_y)}
        class={[
          "absolute right-0 top-full mt-4 min-w-full max-w-60 border border-gray-lighter bg-white rounded-md shadow-xl overflow-hidden hidden",
          "dark:bg-gray-darkest dark:text-white dark:border-gray-darker",
          @class
        ]}
      >
        {render_slot(@inner_block)}
      </nav>
    </div>
    """
  end

  attr :icon, :atom, default: nil
  attr :selected, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate method)

  slot :inner_block, required: true

  def dropdown_link(assigns) do
    ~H"""
    <.link
      class={[
        "flex items-center gap-3 px-4 py-3 text-sm font-semibold whitespace-nowrap hover:bg-primary hover:text-white",
        @selected && "text-primary",
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} class="size-5" />
      {render_slot(@inner_block)}
    </.link>
    """
  end

  def dropdown_hr(assigns) do
    ~H"""
    <div class="border-b border-b-gray-lighter dark:border-b-gray-darker" />
    """
  end

  def show_dropdown(js \\ %JS{}, id, transition) do
    JS.show(js,
      to: "#" <> id,
      time: 300,
      transition: get_transition(transition, :show)
    )
  end

  def hide_dropdown(js \\ %JS{}, id, transition) do
    JS.hide(js,
      to: "#" <> id,
      time: 150,
      transition: get_transition(transition, :hide)
    )
  end

  defp get_transition(:slide_x, :show),
    do: {"transition-all transform ease-out duration-300", "opacity-0 translate-x-full", "opacity-100 translate-x-0"}

  defp get_transition(:slide_x, :hide),
    do: {"transition-all transform ease-in duration-150", "opacity-100 translate-x-0", "opacity-0 -translate-x-4"}

  defp get_transition(:slide_y, :show),
    do:
      {"transition-all transform ease-out duration-300", "opacity-0 -translate-y-4 scale-95",
       "opacity-100 translate-y-0 scale-100"}

  defp get_transition(:slide_y, :hide),
    do:
      {"transition-all transform ease-in duration-150", "opacity-100 translate-y-0 scale-100",
       "opacity-0 -translate-y-4 scale-95"}
end
