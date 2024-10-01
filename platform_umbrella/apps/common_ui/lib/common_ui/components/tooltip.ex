defmodule CommonUI.Components.Tooltip do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon
  import CommonUI.TextHelpers

  alias CommonUI.IDHelpers

  attr :target_id, :string, required: true
  attr :tippy_options, :map, default: %{}
  attr :rest, :global
  slot :inner_block

  @doc """
  Tooltip component. This is a stateless component that actually has a computed id

  This component will not be visible as its' `hidden` however on mount
  it uses the Tooltip hook to create a tippy tooltip targeting the `target_id`
  element. The innerHTML is then used as the content for any tippy tooltip needed.
  """
  def tooltip(assigns) do
    ~H"""
    <div
      class="hidden"
      id={"tooltip-#{@target_id}"}
      phx-hook="Tooltip"
      data-target={@target_id}
      data-tippy-options={Jason.encode!(@tippy_options)}
    >
      <div {@rest}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr :id, :string, required: false, default: nil
  attr :class, :string, required: false, default: ""
  slot :inner_block

  def help_question_mark(assigns) do
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <div :if={@inner_block != nil && @inner_block != []} class={@class}>
      <.icon name={:question_mark_circle} id={@id} class="w-6 h-auto" />
      <.tooltip target_id={@id}>
        <%= render_slot(@inner_block) %>
      </.tooltip>
    </div>
    """
  end

  slot :inner_block, required: true
  slot :tooltip
  attr :class, :string, default: ""
  attr :rest, :global

  def hover_tooltip(%{tooltip: tooltip} = assigns) when tooltip == nil or tooltip == [] do
    ~H"""
    <%= render_slot(@inner_block) %>
    """
  end

  def hover_tooltip(assigns) do
    ~H"""
    <div class={["group/hover-tooltip relative", @class]} {@rest}>
      <div
        class={
          [
            # The tooltip is hidden by default and is shown when the user hovers over the element
            "invisible",
            # Group hover and focus within are used to show the tooltip when the user hovers
            "group-hover/hover-tooltip:visible group-focus-within/hover-tooltip:visible",
            # Move the tooltip up and over
            "absolute -translate-x-1 -translate-y-full",
            "rounded-md shadow-md p-2",
            "bg-white/90 text-gray-darkest"
          ]
        }
        role="tooltip"
        aria-hidden="true"
      >
        <%= render_slot(@tooltip) %>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :value, :string, default: ""
  attr :class, :string, default: nil
  attr :length, :integer, default: 48

  def truncate_tooltip(%{value: v, length: l} = assigns) when byte_size(v) <= l do
    ~H"""
    <div class={@class}>
      <%= @value %>
    </div>
    """
  end

  def truncate_tooltip(%{} = assigns) do
    ~H"""
    <.hover_tooltip class={@class}>
      <:tooltip>
        <div class="max-w-md">
          <p class="break-words"><%= @value %></p>
        </div>
      </:tooltip>
      <%= truncate(@value, length: @length) %>
    </.hover_tooltip>
    """
  end
end
