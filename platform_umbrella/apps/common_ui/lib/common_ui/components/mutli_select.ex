defmodule CommonUI.Components.MutliSelect do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Container
  import CommonUI.Components.Icon
  import Phoenix.Naming, only: [humanize: 1]

  alias CommonUI.IDHelpers
  alias Phoenix.HTML.Form

  attr :width_class, :string, default: "w-96"
  attr :form, :any, default: nil
  attr :field, :atom, default: nil
  attr :label, :string, default: nil
  attr :options, :list, default: []
  attr :change_event, :string, default: "multiselect-change"
  attr :phx_target, :any, default: nil
  attr :rest, :global
  attr :id, :string, default: nil

  def muliselect_input(assigns) do
    # If :id in assigns is not provided or is nil, generate a random id
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <div class={["relative", @width_class]} {@rest}>
      <label phx-feedback-for={feedback_for(@form, @field)}>
        <%= @label || humanize(@field.name) %>
      </label>
      <!-- Select value display and chevron for open/close -->
      <.flex
        class={[
          "rounded-md border border-gray-light dark:border-gray-darkest h-12 items-center p-2 block",
          @width_class
        ]}
        phx-click={toggle_dropdown(@id)}
      >
        <.flex class={["grow m-1 overflow-x-clip"]} gaps="1">
          <div
            :for={%{selected: true} = opt <- @options}
            class="py-2 px-2 shadow-sm rounded-full bg-primary text-gray-darkest font-sans font-semibold text-sm"
          >
            <%= opt.label %>
          </div>
        </.flex>

        <div class="justify-around items-center flex grow-0">
          <.icon
            name={:chevron_down}
            class="h-5 w-5 text-gray-darkest dark:text-gray-lighter transition-transform duration-200"
            id={chevron_id(@id)}
          />
        </div>
      </.flex>
      <!-- Select options -->
      <.flex
        class={[
          "absolute z-10 mt-1 flex-col",
          "max-h-60 w-full overflow-auto rounded-md bg-white dark:bg-gray-darkest p-4",
          "text-gray-darkest dark:text-gray-lighter text-base",
          "shadow-lg ring-1 ring-black ring-opacity-5",
          "focus:outline-none",
          "hidden transition-transform duration-200",
          @width_class
        ]}
        id={dropdown_id(@id)}
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

          <label phx-feedback-for={feedback_for(@form, @field)}>
            <%= value.label %>
          </label>

          <PC.input
            :if={@field && value.selected}
            type="hidden"
            field={@field}
            value={value.value}
            multiple
          />
        </.flex>
      </.flex>
    </div>
    """
  end

  defp feedback_for(nil, _), do: nil
  defp feedback_for(_, nil), do: nil
  defp feedback_for(form, %{name: field_name} = _field), do: Form.input_name(form, field_name)

  defp dropdown_id(nil), do: nil
  defp dropdown_id(id), do: "dropdown_#{id}"

  defp chevron_id(nil), do: nil
  defp chevron_id(id), do: "chevron_#{id}"

  defp toggle_dropdown(js \\ %JS{}, id) do
    js
    |> JS.toggle_class("hidden", to: "##{dropdown_id(id)}")
    |> JS.toggle_class("rotate-180", to: "##{chevron_id(id)}")
  end
end
