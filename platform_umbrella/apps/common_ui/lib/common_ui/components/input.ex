defmodule CommonUI.Components.Input do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon
  import CommonUI.ErrorHelpers
  import Phoenix.HTML.Form

  attr :name, :any
  attr :value, :any
  attr :field, Phoenix.HTML.FormField
  attr :errors, :list, default: []
  attr :force_feedback, :boolean, default: false
  attr :label, :string, default: nil
  attr :note, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :type, :string, default: "text"
  attr :icon, :atom, default: nil
  attr :options, :list, default: []
  attr :multiple, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(autocomplete autofocus maxlength disabled required)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <label phx-feedback-for={if !@force_feedback, do: @name}>
      <.label label={@label} note={@note} />

      <select
        name={@name}
        multiple={@multiple}
        required={!@multiple}
        class={[
          input_class(@errors),
          @multiple == false &&
            "bg-caret bg-[length:9px] bg-[right_0.8rem_center] cursor-pointer",
          @class
        ]}
        {@rest}
      >
        <option :if={@multiple == false} value="" disabled selected>
          <%= assigns[:placeholder] %>
        </option>

        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>

      <.error errors={@errors} />
    </label>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <label phx-feedback-for={if !@force_feedback, do: @name}>
      <.label label={@label} note={@note} />

      <textarea
        name={@name}
        placeholder={@placeholder}
        class={[
          input_class(@errors),
          @class
        ]}
        {@rest}
      ><%= normalize_value("textarea", @value) %></textarea>

      <.error errors={@errors} />
    </label>
    """
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input
      name={@name}
      type="hidden"
      value={normalize_value(@type, @value)}
      class={[input_class(@errors), @class]}
      {@rest}
    />
    """
  end

  def input(assigns) do
    ~H"""
    <label phx-feedback-for={if !@force_feedback, do: @name}>
      <.label label={@label} note={@note} />

      <div class="relative">
        <input
          name={@name}
          type={@type}
          placeholder={@placeholder}
          value={normalize_value(@type, @value)}
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

      <.error errors={@errors} />
    </label>
    """
  end

  defp input_class([_ | _] = _errors) do
    [
      "phx-feedback:bg-error-light phx-feedback:border-error",
      "phx-feedback:dark:bg-error-dark phx-feedback:dark:placeholder:text-error",
      input_class(nil)
    ]
  end

  defp input_class(_) do
    [
      "px-3 py-2 w-full rounded-lg focus:ring-0",
      "text-sm text-gray-darkest dark:text-gray-lighter",
      "placeholder:text-gray-light dark:placeholder:text-gray-dark invalid:text-gray-light dark:invalid:text-gray-dark",
      "border border-gray-lighter dark:border-gray-darker-tint",
      "hover:border-primary dark:hover:border-gray focus:border-primary dark:focus:border-gray",
      "bg-gray-lightest dark:bg-gray-darkest-tint"
    ]
  end

  attr :label, :string, default: nil
  attr :note, :string, default: nil

  defp label(assigns) do
    ~H"""
    <div class="flex items-center gap-4 mb-2 text-sm text-gray-darkest">
      <span :if={@label}><%= @label %></span>
      <span :if={@note} class="text-xs text-gray-light"><%= @note %></span>
    </div>
    """
  end

  attr :errors, :list, default: []

  defp error(assigns) do
    ~H"""
    <div
      :for={error <- @errors}
      class="flex items-center gap-2 text-xs text-error font-semibold mt-2 phx-no-feedback:hidden"
    >
      <.icon name={:exclamation_circle} mini class="size-4 fill-error" />
      <span><%= error %></span>
    </div>
    """
  end
end
