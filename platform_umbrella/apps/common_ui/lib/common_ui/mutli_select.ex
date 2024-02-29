defmodule CommonUI.MutliSelect do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Container
  import Phoenix.Naming, only: [humanize: 1]

  alias Phoenix.HTML.Form

  attr :width_class, :string, default: "w-96"
  attr :form, :any, default: nil
  attr :field, :atom, default: nil
  attr :label, :string, default: nil
  attr :options, :list, default: []
  attr :change_event, :string, default: "multiselect-change"
  attr :phx_target, :any, default: nil
  attr :rest, :global

  def muliselect_input(assigns) do
    ~H"""
    <div
      class={["relative", @width_class]}
      x-data="{ open: false }"
      x-on:click.away="open = false"
      {@rest}
    >
      <label phx-feedback-for={Form.input_name(@form, @field.name)}>
        <%= @label || humanize(@field.name) %>
      </label>
      <!-- Select value display and chevron for open/close -->
      <.flex
        @click="open = !open"
        class={[
          "rounded-md border border-gray-light dark:border-gray-darkest h-12 items-center p-2 block",
          @width_class
        ]}
      >
        <.flex class={["grow m-1 overflow-x-clip"]} gaps="1">
          <div
            :for={%{selected: true} = opt <- @options}
            class="py-2 px-2 shadow-md rounded-full bg-primary text-gray-darkest font-sans font-semibold text-sm"
          >
            <%= opt.label %>
          </div>
        </.flex>

        <div class="justify-around items-center flex grow-0" @click="open = !open">
          <.icon
            name={:chevron_down}
            class="h-5 w-5 text-gray-darkest dark:text-gray-lighter"
            x-show="!open"
          />
          <.icon
            name={:chevron_up}
            class="h-5 w-5 text-gray-darkest dark:text-gray-lighter"
            x-show="open"
            x-cloak
          />
        </div>
      </.flex>
      <!-- Select options -->
      <.flex
        class={[
          "absolute z-10 mt-1 flex-col",
          "max-h-60 w-full overflow-auto rounded-md bg-white dark:bg-gray-darkest p-4",
          "text-gray-darkest dark:text-gray-lighter text-base shadow-lg ring-1 ring-black ring-opacity-5",
          "focus:outline-none",
          @width_class
        ]}
        x-show="open"
        x-cloak
      >
        <.flex :for={value <- @options} class="w-full flex-row items-center justify-between">
          <input
            name={value.value}
            type="checkbox"
            class="h-5 w-5 rounded border-gray-light text-primary-light"
            phx-change={@change_event}
            phx-target={@phx_target}
            value={value.value}
            checked={value.selected}
            data-phx-checked={value.selected}
          />

          <label phx-feedback-for={Form.input_name(@form, @field.name)}>
            <%= value.label %>
          </label>

          <PC.input :if={value.selected} type="hidden" field={@field} value={value.value} multiple />
        </.flex>
      </.flex>
    </div>
    """
  end
end
