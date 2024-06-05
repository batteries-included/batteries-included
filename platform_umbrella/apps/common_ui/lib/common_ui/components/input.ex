defmodule CommonUI.Components.Input do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Dropdown
  import CommonUI.Components.Icon
  import CommonUI.ErrorHelpers
  import Phoenix.HTML
  import Phoenix.HTML.Form

  alias CommonUI.IDHelpers

  attr :name, :any
  attr :value, :any
  attr :checked, :boolean
  attr :field, Phoenix.HTML.FormField
  attr :errors, :list, default: []
  attr :force_feedback, :boolean, default: false
  attr :label, :string, default: nil
  attr :label_note, :string, default: nil
  attr :note, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :placeholder_selectable, :boolean, default: false
  attr :type, :string, default: "text"
  attr :icon, :atom, default: nil
  attr :options, :list, default: []
  attr :multiple, :boolean, default: false
  attr :debounce, :any, default: "blur"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(autocomplete autofocus step maxlength disabled required)

  # Used for range sliders
  attr :min, :any, default: 0
  attr :max, :any, default: nil
  attr :lower_boundary, :any, default: nil
  attr :upper_boundary, :any, default: nil
  attr :ticks, :list, default: []
  attr :tick_click, :any, default: nil
  attr :tick_target, :any, default: nil
  attr :show_value, :boolean, default: true

  # Used for radio buttons
  slot :option do
    attr :value, :string, required: true
    attr :class, :any
  end

  slot :inner_block

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> assign_new(:checked, fn %{value: value} ->
      !Enum.any?(["false", "off", nil], &(html_escape(&1) == html_escape(value)))
    end)
    |> input()
  end

  def input(%{type: "multiselect"} = assigns) do
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <div phx-feedback-for={if !@force_feedback, do: @name}>
      <.dropdown id={"#{@id}-dropdown"} class="!mt-1 max-h-64 !overflow-auto">
        <:trigger>
          <.label label={@label} />

          <div class={[
            input_class(@errors),
            "flex flex-wrap items-center gap-x-1 gap-y-1.5 min-h-[38px]",
            "bg-caret bg-no-repeat bg-[length:9px] bg-[right_0.8rem_center] cursor-pointer",
            @class
          ]}>
            <div
              :for={value <- @value}
              class={[
                "py-0.5 px-2.5 shadow-sm rounded-full text-xs font-semibold",
                "bg-gray-lighter dark:bg-gray-darker-tint text-gray-dark dark:text-gray-light"
              ]}
            >
              <%= value %>
            </div>
          </div>
        </:trigger>

        <label
          :for={option <- @options}
          class="flex items-center gap-3 px-3 py-2 text-sm hover:bg-gray-lightest cursor-pointer"
        >
          <input
            type="checkbox"
            name={@name <> "[]"}
            value={option.value}
            checked={Enum.member?(@value, option.value)}
            class="size-5 text-primary rounded cursor-pointer checked:border-primary checked:hover:border-primary"
          />

          <%= option.name %>
        </label>
      </.dropdown>

      <div :if={@note} class={note_class()}><%= @note %></div>
      <.error errors={@errors} />
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <label phx-feedback-for={if !@force_feedback, do: @name}>
      <.label label={@label} />

      <select
        name={@name}
        multiple={@multiple}
        required={!@multiple && !@placeholder_selectable}
        class={[
          input_class(@errors),
          "invalid:text-gray-light dark:invalid:text-gray-dark",
          @multiple == false && "bg-caret bg-[length:9px] bg-[right_0.8rem_center] cursor-pointer",
          @class
        ]}
        {@rest}
      >
        <option
          :if={@multiple == false}
          value=""
          disabled={!@placeholder_selectable}
          selected={!@value || @value == ""}
        >
          <%= assigns[:placeholder] %>
        </option>

        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>

      <div :if={@note} class={note_class()}><%= @note %></div>
      <.error errors={@errors} />
    </label>
    """
  end

  def input(%{type: "checkbox"} = assigns) do
    ~H"""
    <label
      phx-feedback-for={if !@force_feedback, do: @name}
      class={["flex flex-wrap items-center gap-x-2 cursor-pointer", @class]}
    >
      <input type="hidden" name={@name} value="false" />
      <input
        type="checkbox"
        name={@name}
        value="true"
        checked={@checked}
        class={[
          "size-5 text-primary rounded cursor-pointer",
          "checked:border-primary checked:hover:border-primary",
          @errors == [] && "border-gray-lighter hover:border-primary",
          @errors != [] && "phx-feedback:bg-red-50 phx-feedback:border-red-200"
        ]}
      />

      <span class={label_class()}>
        <%= @label %>
        <%= render_slot(@inner_block) %>
      </span>

      <div :if={@note} class={note_class()}><%= @note %></div>
      <.error errors={@errors} class="w-full mt-2" />
    </label>
    """
  end

  def input(%{type: "radio"} = assigns) do
    ~H"""
    <div
      phx-feedback-for={if !@force_feedback, do: @name}
      class={["flex flex-wrap items-center gap-x-6", @class]}
    >
      <label
        :for={option <- @option}
        class={["inline-flex flex-wrap items-center gap-2 cursor-pointer", Map.get(option, :class)]}
      >
        <input
          type="radio"
          name={@name}
          value={option.value}
          checked={to_string(@value) == to_string(option.value)}
          class={[
            "size-5 text-primary rounded-full cursor-pointer",
            "checked:border-primary checked:hover:border-primary",
            @errors == [] && "border-gray-lighter hover:border-primary",
            @errors != [] && "phx-feedback:bg-red-50 phx-feedback:border-red-200"
          ]}
        />

        <span class={label_class()}>
          <%= render_slot(option) %>
        </span>
      </label>

      <div :if={@note} class={note_class()}><%= @note %></div>
      <.error errors={@errors} class="w-full mt-2" />
    </div>
    """
  end

  def input(%{type: "range"} = assigns) do
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <div id={@id} class={@class} phx-hook="Range">
      <div class="relative pb-6">
        <div
          :for={{label, percentage} <- @ticks}
          style={"left: calc(#{round(percentage * 100)}% + #{round((0.5 - percentage) * 24)}px)"}
          class="absolute flex flex-col items-center -translate-x-1/2"
        >
          <span
            phx-value-label={label}
            phx-value-percentage={percentage}
            phx-value-value={(@max - @min) * percentage}
            phx-target={@tick_target}
            phx-click={!out_of_bounds?(assigns, percentage) && @tick_click}
            class={[
              "font-semibold text-sm text-gray select-none",
              !out_of_bounds?(assigns, percentage) && @tick_click && "cursor-pointer hover:underline",
              out_of_bounds?(assigns, percentage) &&
                "text-gray-lighter dark:text-gray-darker cursor-default hover:no-underline"
            ]}
          >
            <%= label %>
          </span>

          <span class="w-0.5 bg-gray-lighter dark:bg-gray-darkest-tint h-3 mt-1 rounded-lg" />
        </div>

        <datalist :if={@ticks != []} id={"#{@id}-ticks"}>
          <option :for={{_, percentage} <- @ticks} value={round((@max - @min) * percentage)} />
        </datalist>
      </div>

      <div class="relative">
        <input
          id={"#{@id}-input"}
          type="range"
          name={@name}
          value={@value}
          min={@min}
          max={@max}
          data-lower-boundary={@lower_boundary}
          data-upper-boundary={@upper_boundary}
          list={"#{@id}-ticks"}
          class={[
            "relative z-30 appearance-none bg-transparent cursor-pointer w-full",
            "slider-thumb:appearance-none slider-thumb:box-border slider-thumb:rounded-full",
            "slider-thumb:border-2 slider-thumb:border-solid slider-thumb:border-primary",
            "slider-thumb:bg-white slider-thumb:dark:bg-gray-darkest-tint",
            @show_value && "h-[32px] slider-thumb:size-[32px]",
            !@show_value && "h-[24px] slider-thumb:size-[24px] "
          ]}
          {@rest}
        />

        <div
          id={"#{@id}-progress-bg"}
          phx-update="ignore"
          class={[
            "absolute h-[4px] z-10 bg-gray-lighter dark:bg-gray-darkest-tint w-full rounded pointer-events-none",
            @show_value && "top-[14px]",
            !@show_value && "top-[10px]"
          ]}
        />

        <div
          id={"#{@id}-progress"}
          phx-update="ignore"
          class={[
            "absolute h-[4px] z-20 bg-primary rounded-l pointer-events-none",
            @show_value && "top-[14px]",
            !@show_value && "top-[10px]"
          ]}
        />

        <div
          :if={@show_value}
          id={"#{@id}-value"}
          phx-update="ignore"
          class="absolute top-0 bottom-0 inline-flex items-center justify-center size-[32px] z-30 font-semibold text-primary pointer-events-none"
        >
          <%= @value %>
        </div>
      </div>

      <.error errors={@errors} class="w-full mt-2" />
    </div>
    """
  end

  def input(%{type: "switch"} = assigns) do
    ~H"""
    <label
      phx-feedback-for={if !@force_feedback, do: @name}
      class={[
        "inline-flex flex-wrap items-center justify-between gap-2 cursor-pointer select-none",
        @class
      ]}
    >
      <span class={label_class()}><%= @label %></span>

      <div>
        <input
          type="checkbox"
          name={@name}
          value={@value}
          checked={@checked}
          class="peer sr-only"
          {@rest}
        />

        <div class={[
          "relative w-[44px] h-[24px] rounded-full bg-gray-lightest border border-gray-lighter hover:border-primary",
          "dark:bg-gray-darkest-tint dark:border-gray-darker dark:hover:border-gray-dark",
          "after:content-[''] after:absolute after:top-[3px] after:start-[3px] after:w-[16px] after:h-[16px]",
          "after:rounded-full after:bg-gray after:transition-all",
          "peer-checked:after:translate-x-[20px] peer-checked:after:bg-primary",
          "peer-disabled:cursor-not-allowed peer-disabled:hover:border-gray-lighter",
          "peer-disabled:after:bg-gray-lighter peer-checked:peer-disabled:after:bg-primary-light"
        ]} />
      </div>

      <div :if={@note} class={note_class()}><%= @note %></div>
      <.error errors={@errors} class="w-full mt-0" />
    </label>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <label phx-feedback-for={if !@force_feedback, do: @name}>
      <.label label={@label} />

      <textarea
        name={@name}
        placeholder={@placeholder}
        phx-debounce={@debounce}
        class={[
          input_class(@errors),
          @class
        ]}
        {@rest}
      ><%= normalize_value("textarea", @value) %></textarea>

      <div :if={@note} class={note_class()}><%= @note %></div>
      <.error errors={@errors} />
    </label>
    """
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input
      type="hidden"
      name={@name}
      value={normalize_value(@type, @value)}
      class={[input_class(@errors), @class]}
      {@rest}
    />
    """
  end

  def input(assigns) do
    ~H"""
    <label phx-feedback-for={if !@force_feedback, do: @name}>
      <div class="flex items-center justify-between mb-2">
        <.label label={@label} class="mb-0" />

        <div :if={@label_note} class="font-medium text-sm text-gray-light dark:text-gray-dark">
          <%= @label_note %>
        </div>
      </div>

      <div class="relative">
        <input
          type={@type}
          name={@name}
          value={normalize_value(@type, @value)}
          placeholder={@placeholder}
          phx-debounce={@debounce}
          class={[
            input_class(@errors),
            @class
          ]}
          {@rest}
        />

        <.icon
          :if={@icon}
          name={@icon}
          class="absolute top-0 bottom-0 right-3 w-5 h-full pointer-events-none text-gray"
        />
      </div>

      <div :if={@note} class={note_class()}><%= @note %></div>
      <.error errors={@errors} />
    </label>
    """
  end

  defp input_class([_ | _] = _errors) do
    [
      "phx-feedback:bg-red-50 phx-feedback:border-red-200",
      "phx-feedback:dark:bg-red-950 phx-feedback:dark:border-red-900",
      input_class(nil)
    ]
  end

  defp input_class(_) do
    [
      "px-3 py-2 w-full rounded-lg focus:ring-0",
      "text-sm text-gray-darkest dark:text-gray-lighter",
      "placeholder:text-gray-light dark:placeholder:text-gray-dark",
      "border border-gray-lighter dark:border-gray-darker-tint",
      "hover:border-primary dark:hover:border-gray focus:border-primary dark:focus:border-gray",
      "bg-gray-lightest dark:bg-gray-darkest-tint"
    ]
  end

  defp note_class, do: "text-xs text-gray-light mt-2"

  defp out_of_bounds?(%{min: min, max: max, lower_boundary: lower, upper_boundary: upper}, percentage) do
    # offset the percentage a tiny bit in case a boundary is right on a tick
    value = (max - min) * (percentage + 0.0001)

    (lower && value < lower) || (upper && value > upper)
  end

  attr :label, :string, default: nil
  attr :class, :any, default: "mb-2"

  defp label(assigns) do
    ~H"""
    <div :if={@label} class={[label_class(), @class]}>
      <%= @label %>
    </div>
    """
  end

  defp label_class, do: "text-sm text-gray-darkest dark:text-gray-lighter"

  attr :errors, :list, default: []
  attr :class, :any, default: "mt-2"

  defp error(assigns) do
    ~H"""
    <div
      :for={error <- @errors}
      class={[
        "flex items-center gap-2 text-xs text-red-500 font-semibold phx-no-feedback:hidden",
        @class
      ]}
    >
      <.icon name={:exclamation_circle} mini class="size-4 fill-red-500" />
      <span><%= error %></span>
    </div>
    """
  end
end
