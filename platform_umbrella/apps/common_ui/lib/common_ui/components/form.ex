defmodule CommonUI.Components.Form do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Panel
  import CommonUI.Gettext, warn: false

  @doc """
  Renders a simple form with a css grid based 2 column layout.

  ## Examples

      <.simple_form :let={f} for={:user} phx-change="validate" phx-submit="save">
        <.input field={{f, :email}} label="Email"/>
        <.input field={{f, :username}} label="Username" />
        <:actions>
          <.button variant="primary" type="submit">Save</.button>
        <:actions>
      </.simple_form>
  """
  attr :for, :any, default: nil, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :variant, :string, values: ["stepped", "nested"]
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(%{variant: "stepped"} = assigns) do
    ~H"""
    <.form for={@for} as={@as} class={["flex flex-col h-full", @class]} novalidate {@rest}>
      <div class={["grid lg:grid-cols-[2fr,1fr] content-start flex-1 gap-4", @class]}>
        <div class="row-start-2 lg:row-start-1">
          <.panel title={@title}>
            <.simple_form variant="nested">
              <%= render_slot(@inner_block) %>
            </.simple_form>
          </.panel>
        </div>

        <div>
          <.panel :if={@description} title="Info">
            <p><%= @description %></p>
          </.panel>
        </div>
      </div>

      <div class="flex items-center justify-end gap-4">
        <%= render_slot(@actions) %>
      </div>
    </.form>
    """
  end

  def simple_form(%{variant: "nested"} = assigns) do
    ~H"""
    <div class={["grid grid-cols-1 md:grid-cols-2 gap-4", @class]}>
      <%= render_slot(@inner_block) %>
    </div>

    <div class="flex items-center justify-between gap-2 mt-2">
      <%= render_slot(@actions) %>
    </div>
    """
  end

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8">
        <div class="grid grid-cols-1 mt-6 sm:gap-y-4 gap-y-8 gap-x-4 sm:gap-x-8 sm:grid-cols-2">
          <%= render_slot(@inner_block, f) %>
        </div>
        <div :for={action <- @actions} class="flex items-center justify-between gap-2 mt-2">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  attr :label, :string, default: nil
  attr :rest, :global, include: ~w(name value)

  def switch(assigns) do
    ~H"""
    <label class="relative inline-flex items-center mb-4 cursor-pointer">
      <input type="checkbox" {@rest} class="sr-only peer" />
      <div class="dark:peer-focus:ring-primary after:peer-checked:bg-primary h-[24px] w-[42px] rounded-full border border-gray-light bg-white after:absolute after:left-[5px] after:top-1 after:h-[16px] after:w-[16px] after:rounded-full after:border-none after:bg-gray-dark dark:after:bg-gray after:transition-all after:content-[''] peer-checked:after:translate-x-full peer-checked:after:border-none dark:border-gray-darker dark:bg-gray-darkest">
      </div>
      <span :if={@label} class="ml-3 text-sm font-medium text-gray-darkest dark:text-gray-light">
        <%= @label %>
      </span>
    </label>
    """
  end
end
