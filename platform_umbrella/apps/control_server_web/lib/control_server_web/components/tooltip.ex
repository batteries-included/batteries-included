defmodule ControlServerWeb.Tooltip do
  @moduledoc """
  Components that use or provide tooltips. The
  """

  use ControlServerWeb, :html

  attr :target_id, :string, required: true
  slot :inner_block

  @doc """
  Tooltip component. This is a stateless component that actually has a computed id

  This component will not be visible as its' `hidden` however on mount
  it uses the Tooltip hook to create a tippy tooltip targeting the `target_id`
  element. The innerHTML is then used as the content for any tippy tooltip needed.
  """
  def tooltip(assigns) do
    ~H"""
    <div class="hidden" id={"tooltip-#{@target_id}"} phx-hook="Tooltip" data-target={"#{@target_id}"}>
      <div class="min-w-24 bg-white shadow-sm p-2 rounded-md">
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
    <div class={build_class(["cursor-pointer", @class])} id={@id}>
      <Heroicons.question_mark_circle class="w-6 h-auto" />
      <.tooltip target_id={@id}>
        <%= render_slot(@inner_block) %>
      </.tooltip>
    </div>
    """
  end
end
