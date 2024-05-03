defmodule CommonUI.Components.Dropdown do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon

  alias CommonUI.IDHelpers

  attr :id, :string
  attr :class, :any, default: nil

  slot :trigger
  slot :item, validate_attrs: false

  def dropdown(assigns) do
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <div class="relative z-40">
      <div class="cursor-pointer" phx-click={show_dropdown(@id, :slide_y)}>
        <%= render_slot(@trigger) %>
      </div>

      <nav
        role="navigation"
        id={@id}
        class={[dropdown_class(), @class]}
        phx-click-away={hide_dropdown(@id, :slide_y)}
      >
        <.link
          :for={item <- @item}
          class={[
            "flex items-center gap-3 px-4 py-3 text-sm font-semibold whitespace-nowrap hover:bg-primary hover:text-white",
            Map.get(item, :selected) && "text-primary",
            Map.get(item, :class)
          ]}
          {assigns_to_attributes(item, [:icon, :selected, :class])}
        >
          <.icon :if={icon = Map.get(item, :icon)} name={icon} class="size-5" />
          <%= render_slot(item) %>
        </.link>
      </nav>
    </div>
    """
  end

  def dropdown_class do
    [
      "absolute right-0 top-full mt-4 min-w-full max-w-60 border border-gray-lighter bg-white rounded-md shadow-xl overflow-hidden hidden",
      "dark:bg-gray-darkest dark:text-white"
    ]
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
