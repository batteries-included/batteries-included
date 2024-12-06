defmodule CommonUI.Components.Panel do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Container
  import CommonUI.Components.Typography

  attr :title, :string, default: nil
  attr :title_size, :string, default: "md", values: ["md", "lg"]
  attr :variant, :string, values: ["gray", "shadowed"]
  attr :class, :any, default: nil
  attr :inner_class, :any, default: nil
  attr :rest, :global

  slot :menu
  slot :inner_block

  def panel(assigns) do
    ~H"""
    <div class={[panel_class(assigns[:variant]), @class]} {@rest}>
      <.flex :if={@title} class="items-center justify-between flex-wrap w-full px-6 pt-5">
        <.h2 :if={@title_size == "lg"}>{@title}</.h2>
        <.h3 :if={@title_size == "md"} class="font-semibold">{@title}</.h3>

        {if @menu, do: render_slot(@menu)}
      </.flex>

      <div class={["relative flex-1 px-6 py-5", @inner_class]}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp panel_class("gray") do
    [
      "bg-gray-lightest rounded-lg dark:bg-gray-darker/20",
      panel_class()
    ]
  end

  defp panel_class("shadowed") do
    [
      "w-full max-w-md bg-white dark:bg-gray-darkest shadow-2xl shadow-gray/30 dark:shadow-black/40 rounded-lg p-2 lg:p-4",
      panel_class()
    ]
  end

  defp panel_class(_) do
    [
      "bg-white border border-gray-lighter rounded-lg dark:bg-gray-darkest/70 dark:border-gray-darker",
      panel_class()
    ]
  end

  defp panel_class do
    "flex flex-col"
  end
end
