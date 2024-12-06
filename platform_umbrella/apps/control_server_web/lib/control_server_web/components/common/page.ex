defmodule ControlServerWeb.Common.Page do
  @moduledoc false
  use Phoenix.Component

  import CommonUI.Components.Button
  import CommonUI.Components.Container
  import CommonUI.Components.Typography

  attr :title, :string, default: nil
  attr :back_link, :string, default: nil
  attr :back_click, :any, default: nil
  attr :class, :any, default: "mb-6"

  slot :menu
  slot :inner_block

  def page_header(assigns) do
    assigns =
      Map.put(assigns, :back_button_attrs, %{
        icon: :arrow_left,
        variant: "icon_bordered"
      })

    ~H"""
    <.flex class={["flex-wrap items-center justify-between", @class]}>
      <.flex class="items-center" gaps={%{sm: 3, lg: 4}}>
        <.button :if={@back_link} link={@back_link} {@back_button_attrs} />
        <.button :if={@back_click} phx-click={@back_click} {@back_button_attrs} />

        <.h3 :if={@title} class="text-2xl font-medium text-black dark:text-white">
          {@title}
        </.h3>

        {render_slot(@menu)}
      </.flex>

      {render_slot(@inner_block)}
    </.flex>
    """
  end
end
