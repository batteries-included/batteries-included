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
      <div class="cursor-pointer" phx-click={JS.show(to: "##{@id}")}>
        <%= render_slot(@trigger) %>
      </div>

      <nav role="navigation" id={@id} class={[dropdown_class(), @class]} phx-click-away={JS.hide()}>
        <.link
          :for={item <- @item}
          class={[
            "flex items-center gap-3 px-4 py-3 text-sm font-semibold whitespace-nowrap hover:bg-primary hover:text-white",
            Map.get(item, :selected) && "text-primary"
          ]}
          phx-click={JS.hide(to: "##{@id}")}
          {assigns_to_attributes(item, [:icon, :selected])}
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
      "absolute right-0 top-full mt-4 border border-gray-lighter bg-white rounded-md shadow-xl overflow-hidden hidden",
      "dark:bg-gray-darkest dark:text-white"
    ]
  end
end
