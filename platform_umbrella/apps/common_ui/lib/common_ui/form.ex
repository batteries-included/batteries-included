defmodule CommonUI.Form do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Gettext, warn: false
  import Phoenix.HTML.Form, only: [input_name: 2, input_id: 2, input_value: 2, humanize: 1]

  alias Phoenix.LiveView.JS

  @doc """
  Renders a simple form with a css grid based 2 column layout.

  ## Examples

      <.simple_form :let={f} for={:user} phx-change="validate" phx-submit="save">
        <.input field={{f, :email}} label="Email"/>
        <.input field={{f, :username}} label="Username" />
        <:actions>
          <.button>Save</.button>
        <:actions>
      </.simple_form>
  """
  attr :for, :any, default: nil, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :rest, :global, doc: "the arbitraty HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

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

  @doc """
  Renders an input with label and error messages.

  A `%Phoenix.HTML.Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={{f, :email}} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any
  attr :name, :any
  attr :label, :string

  attr :type, :string,
    default: "text",
    doc: ~s|one of "text", "textarea", "number" "email", "date", "time", "datetime", "select", "range", "multicheck"|

  attr :value, :any
  attr :field, :any, doc: "a %Phoenix.HTML.Form{}/field name tuple, for example: {f, :email}"
  attr :errors, :list
  attr :wrapper_class, :string, default: "form-control"

  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    doc: "the arbitrary HTML attributes for the input tag",
    include:
      ~w(autocomplete checked disabled form max maxlength min minlength pattern placeholder readonly required size step)

  slot :inner_block

  def input(%{field: {f, field}} = assigns) do
    assigns
    |> assign(field: nil)
    |> assign_new(:name, fn ->
      name = input_name(f, field)
      if assigns.multiple || assigns.type == "multicheck", do: name <> "[]", else: name
    end)
    |> assign_new(:id, fn -> input_id(f, field) end)
    |> assign_new(:value, fn -> input_value(f, field) end)
    |> assign_new(:errors, fn -> translate_errors(f.errors || [], field) end)
    |> assign_new(:label, fn -> humanize(field) end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    ~H"""
    <label phx-feedback-for={@name} class="flex items-center gap-4 pt-10 text-base leading-6">
      <input type="hidden" id={@id} name={@name} value="false" />
      <input
        type="checkbox"
        id={@id}
        name={@name}
        class="toggle toggle-primary"
        value="true"
        checked={input_checked(@rest, @value)}
      />
      <%= @label %>
    </label>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class={[border("select", @errors), "select select-md w-full max-w-x"]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt}><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors} message={msg} />
    </div>
    """
  end

  def input(%{type: "multicheck"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <input type="hidden" name={@name} value="" />
      <.label for={@id}><%= @label %></.label>
      <div class="grid grid-cols-1 gap-2 md:grid-cols-2 xl:grid-cols-4">
        <div :for={o <- @options}>
          <.label for={"#{@name}-#{o}"}><%= o %></.label>
          <input
            type="checkbox"
            id={"#{@name}-#{o}"}
            name={@name}
            class="toggle toggle-primary"
            value={o}
            checked={o in @value}
          />
        </div>
      </div>
      <.error :for={msg <- @errors} message={msg} />
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@wrapper_class}>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id || @name}
        name={@name}
        class={[border("textarea", @errors), "textarea"]}
        {@rest}
      ><%= @value %></textarea>
      <.error :for={msg <- @errors} message={msg} />
    </div>
    """
  end

  def input(%{type: "range"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@wrapper_class}>
      <.label for={@id}><%= @label %></.label>
      <input
        id={@id || @name}
        name={@name}
        value={@value}
        type="range"
        class={["range range-md range-primary w-full"]}
        {@rest}
      />
      <.error :for={msg <- @errors} message={msg} />
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class={@wrapper_class}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id || @name}
        value={@value}
        class={[border("input", @errors), "input-md"]}
        {@rest}
      />
      <.error :for={msg <- @errors} message={msg} />
    </div>
    """
  end

  attr :label, :string, default: nil
  attr :rest, :global, include: ~w(name value)

  def switch(assigns) do
    ~H"""
    <label class="relative inline-flex items-center mb-4 cursor-pointer">
      <input type="checkbox" {@rest} class="sr-only peer" />
      <div class="dark:peer-focus:ring-primary-500 after:peer-checked:bg-primary-500 h-[24px] w-[42px] rounded-full border border-gray-300 bg-white after:absolute after:left-[5px] after:top-1 after:h-[16px] after:w-[16px] after:rounded-full after:border-none after:bg-gray-500 dark:after:bg-gray-400 after:transition-all after:content-[''] peer-checked:after:translate-x-full peer-checked:after:border-none dark:border-gray-600 dark:bg-gray-800">
      </div>
      <span :if={@label} class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300">
        <%= @label %>
      </span>
    </label>
    """
  end

  defp input_checked(%{checked: checked}, _value) when not is_nil(checked), do: checked
  defp input_checked(_rest, value) when is_boolean(value), do: value
  defp input_checked(_rest, value), do: to_string(value) == "true"

  # Border helpers. Yes these are repetitive to make sure
  # that tailwindcss doesn't purge the needed types.
  defp border("input" = _type, [] = _errors), do: "input input-bordered"
  defp border("textarea" = _type, [] = _errors), do: "textarea textarea-bordered"
  defp border("select" = _type, [] = _errors), do: "select select-bordered"

  defp border("input" = _type, [_ | _] = _errors), do: "input input-bordered input-error"

  defp border("select" = _type, [_ | _] = _errors), do: "selct select-bordered select-error"

  defp border("textarea" = _type, [_ | _] = _errors), do: "text-area textarea-bordered textarea-error"

  defp border(type, [] = _errors), do: "#{type} #{type}-secondary #{type}-bordered"

  defp border(type, [_ | _] = _errors), do: "#{type} #{type}-bordered #{type}-error"

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="label">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  attr :message, :string, default: ""

  def error(assigns) do
    ~H"""
    <p class="flex gap-3 mt-3 text-sm leading-6 phx-no-feedback:hidden text-sea-buckthorn-600 input-error">
      <Heroicons.exclamation_circle mini class="mt-0.5 h-5 w-5 flex-none fill-sea-buckthorn-500" />
      <%= @message %>
    </p>
    """
  end

  @doc """
  Editable component.

      <.editable_field
        field_attrs={%{
          field: @form[:storage_size],
          label: "Storage Size",
          type: "number",
          "phx-change": "change_storage_size"
        }}
        editing?={@storage_size_editable}
        toggle_event_target={@myself}
        toggle_event="toggle_storage_size_editable"
        value_when_not_editing={@form[:storage_size].value |> your_custom_formatting()}
      />
  """
  attr :field_attrs, :map, default: %{}, doc: "attrs to pass to <.field> from Petal Components"
  attr :editing?, :boolean, default: false, doc: "whether the field is editable or not"

  attr :toggle_event, :string,
    doc: "the event that will toggle the `editing?` state. Your live view/component should handle it"

  attr :toggle_event_target, :any, doc: "target of the event. In most cases will be `@myself`"

  attr :value_when_not_editing, :string,
    default: nil,
    doc: "optionally format the value how you like. Defaults to the value of the field"

  def editable_field(assigns) do
    assigns = assign_new(assigns, :id, fn -> "editable_field_#{DateTime.to_unix(DateTime.now!("Etc/UTC"))}" end)

    ~H"""
    <div id={@id} class="w-full">
      <div class={"items-center gap-1 w-full phx-click-loading:hidden #{if @editing?, do: "flex", else: "hidden"}"}>
        <PC.field wrapper_class="flex-1" {@field_attrs} />
        <PC.icon_button
          phx-click={toggle_editable(@toggle_event, @toggle_event_target, @id)}
          type="button"
          size="xs"
          class="mt-1"
        >
          <Heroicons.x_mark solid />
        </PC.icon_button>
      </div>

      <div class={"gap-1 phx-click-loading:hidden #{if @editing?, do: "hidden", else: "block"}"}>
        <PC.form_label><%= @field_attrs[:label] %></PC.form_label>
        <div
          phx-click={toggle_editable(@toggle_event, @toggle_event_target, @id)}
          id={"#{@id}_uneditable"}
          class="text-sm py-2 text-gray-500 dark:text-gray-400 cursor-text border border-transparent border-dashed hover:border-gray-300 dark:hover:border-gray-700 px-3 rounded hover:bg-gray-50 dark:hover:bg-gray-800"
        >
          <%= if @value_when_not_editing,
            do: @value_when_not_editing,
            else: get_in(@field_attrs, [:field, :value]) %>
        </div>
        <CommonUI.Tooltip.tooltip target_id={"#{@id}_uneditable"} tippy_options={%{placement: "left"}}>
          Click to edit
        </CommonUI.Tooltip.tooltip>
      </div>
      <PC.spinner class="hidden phx-click-loading:block mt-9" />
    </div>
    """
  end

  defp toggle_editable(event, target, id) do
    JS.push(event, target: target, loading: "##{id}")
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(CommonUI.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(CommonUI.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end
end
