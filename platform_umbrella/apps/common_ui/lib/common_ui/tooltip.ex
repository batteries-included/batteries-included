defmodule CommonUI.Tooltip do
  @moduledoc false
  use CommonUI.Component

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

  attr :id, :string, required: true
  attr :class, :string, required: false, default: ""
  slot :inner_block

  def help_question_mark(assigns) do
    ~H"""
    <div :if={@inner_block != nil && @inner_block != []} class={["cursor-pointer", @class]} id={@id}>
      <Heroicons.question_mark_circle class="w-6 h-auto" />
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

  def hover_tooltip(%{tooltip: []} = assigns) do
    ~H"""
    <%= render_slot(@inner_block) %>
    """
  end

  def hover_tooltip(assigns) do
    ~H"""
    <div class={build_class(["group relative", @class])} {@rest}>
      <div
        class={
          build_class([
            "invisible group-hover:visible group-focus-within:visible",
            "absolute -translate-x-1 -translate-y-full",
            "rounded-md shadow-sm bg-gray-100 bg-opacity-95 p-2"
          ])
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
end
