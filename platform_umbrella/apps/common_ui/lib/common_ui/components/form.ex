defmodule CommonUI.Components.Form do
  @moduledoc false
  use CommonUI, :component
  use Gettext, backend: CommonUI.Gettext, warn: false

  import CommonUI.Components.FlashGroup
  import CommonUI.Components.Markdown
  import CommonUI.Components.Panel
  import CommonUI.Components.Typography

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
  attr :id, :any, default: nil
  attr :variant, :string, values: ["stepped", "nested"]
  attr :flash, :map, default: %{}
  attr :title, :string, default: nil
  attr :description, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(for as method action)

  slot :inner_block, required: true
  slot :actions

  # TODO: Deprecated, remove when everything is migrated to Fieldset component
  def simple_form(%{variant: "stepped"} = assigns) do
    ~H"""
    <.form id={@id} class={["flex flex-col h-full", @class]} novalidate {@rest}>
      <div class={["grid lg:grid-cols-[2fr,1fr] content-start flex-1 gap-4", @class]}>
        <.panel title={@title}>
          <.simple_form variant="nested">
            <.flash_group id={"#{@id}-flash"} flash={@flash} />

            <%= render_slot(@inner_block) %>
          </.simple_form>
        </.panel>

        <.panel :if={@description} title="Description">
          <.markdown content={@description} />
        </.panel>
      </div>

      <div class="flex items-center justify-end gap-4">
        <%= render_slot(@actions) %>
      </div>
    </.form>
    """
  end

  def simple_form(%{variant: "nested"} = assigns) do
    ~H"""
    <div class={["grid grid-cols-1 gap-x-4 gap-y-6", @class]}>
      <%= render_slot(@inner_block) %>
    </div>

    <div :if={@actions != []} class="flex items-center justify-end gap-2 mt-6">
      <%= render_slot(@actions) %>
    </div>
    """
  end

  def simple_form(assigns) do
    ~H"""
    <.form id={@id} {@rest}>
      <.simple_form variant="nested" class={@class}>
        <.h2 :if={@title}><%= @title %></.h2>
        <.flash_group id={"#{@id}-flash"} flash={@flash} />

        <%= render_slot(@inner_block) %>

        <:actions :if={@actions != []}>
          <%= render_slot(@actions) %>
        </:actions>
      </.simple_form>
    </.form>
    """
  end
end
