defmodule CommonUI.Components.ClickFlip do
  @moduledoc """
  This is a click to edit compoent that will flip
  between a display side and an edit side. By default
  the inner_block will be shown. That is the display
  side. When clicked the edit side will be shown and the
  first input will be focused. Clicking away our clicking
  the check mark button will flip back to display.
  """
  use CommonUI, :component

  import CommonUI.Components.Button
  import CommonUI.Components.Container
  import CommonUI.Components.Tooltip

  alias CommonUI.IDHelpers

  slot :inner_block
  slot :hidden

  attr :class, :any, default: nil
  attr :cursor_class, :any, default: "cursor-pointer"
  attr :content_class, :any, default: "min-w-10 py-4"

  attr :tooltip, :string, default: nil
  attr :id, :string, required: false, default: nil

  def click_flip(assigns) do
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <.flex class={@class} id={@id}>
      <div
        class={[
          @cursor_class,
          @content_class,
          "border border-transparent border-dashed hover:border-gray-light dark:hover-border-gray-darkest",
          "rounded-md p-4",
          "hover:bg-gray-lightest/70 dark:hover:bg-gray-darkest/70"
        ]}
        id={content_id(@id)}
        phx-click={show_edit_content(@id)}
      >
        {render_slot(@inner_block)}
        <.tooltip
          :if={@id != nil and @tooltip != nil}
          target_id={content_id(@id)}
          tippy_options={%{placement: "left"}}
        >
          Click to edit
        </.tooltip>
      </div>
      <.flex
        class="items-center grow hidden"
        phx-click-away={hide_edit_content(@id)}
        id={edit_id(@id)}
      >
        {render_slot(@hidden)}
        <.button variant="icon" icon={:check} phx-click={hide_edit_content(@id)} />
      </.flex>
    </.flex>
    """
  end

  defp content_id(nil), do: nil
  defp content_id(id), do: "content_id_#{id}"

  defp edit_id(nil), do: nil
  defp edit_id(id), do: "edit_id_#{id}"

  defp hide_edit_content(js \\ %JS{}, id) do
    js
    |> JS.toggle_class("hidden", to: "##{edit_id(id)}")
    |> JS.toggle_class("hidden", to: "##{content_id(id)}")
  end

  defp show_edit_content(js \\ %JS{}, id) do
    js
    |> JS.toggle_class("hidden", to: "##{content_id(id)}")
    |> JS.toggle_class("hidden", to: "##{edit_id(id)}")
    |> JS.focus_first()
  end
end
