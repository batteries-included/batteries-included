defmodule CommonUI.Components.Fieldset do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.FlashGroup
  import CommonUI.Components.Typography
  import CommonUI.IDHelpers

  attr :id, :string
  attr :responsive, :boolean, default: false
  attr :flash, :map, default: %{}
  attr :title, :string, default: nil
  attr :class, :any, default: nil
  attr :inner_class, :any, default: nil

  slot :inner_block, required: true

  slot :actions do
    attr :class, :any
  end

  def fieldset(assigns) do
    assigns = provide_id(assigns)

    ~H"""
    <div class={["w-full", @class]}>
      <.h2 :if={@title}><%= @title %></.h2>

      <div class={[
        "gap-x-4 gap-y-6",
        @responsive && "grid grid-cols-1 lg:grid-cols-2",
        !@responsive && "flex flex-col",
        @inner_class
      ]}>
        <.flash_group id={"#{@id}-flash"} flash={@flash} class="col-span-2" />

        <%= render_slot(@inner_block) %>
      </div>

      <div
        :for={actions <- @actions}
        class={["flex items-center justify-end gap-2 mt-6", actions[:class]]}
      >
        <%= render_slot(actions) %>
      </div>
    </div>
    """
  end
end
