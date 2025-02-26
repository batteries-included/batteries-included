defmodule ControlServerWeb.OllamaFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Ollama.ModelInstance
  alias CommonCore.Util.Memory

  attr :class, :any, default: nil
  attr :form, :any, required: true
  attr :action, :atom, default: nil

  def model_form(assigns) do
    ~H"""
    <.fieldset responsive class={@class}>
      <.field>
        <:label>Name</:label>
        <.input field={@form[:name]} autofocus={@action == :new} disabled={@action != :new} />
      </.field>

      <.field>
        <:label>Model</:label>
        <.input
          field={@form[:model]}
          type="select"
          placeholder="Select Model"
          options={ModelInstance.model_options_for_select()}
        />
      </.field>
    </.fieldset>
    """
  end

  attr :class, :any, default: nil
  attr :form, :any, required: true

  def size_form(assigns) do
    ~H"""
    <.fieldset class={@class}>
      <.field>
        <:label>Size</:label>
        <.input
          field={@form[:virtual_size]}
          type="select"
          placeholder="Choose a size"
          options={ModelInstance.preset_options_for_select()}
        />
      </.field>

      <.data_list
        variant="horizontal-bolded"
        data={[
          {"Memory limits:", Memory.humanize(@form[:memory_limits].value)},
          {"CPU Request:", @form[:cpu_requested].value}
        ]}
      />
      <.field>
        <:label>GPU Count</:label>
        <.input field={@form[:gpu_count]} type="number" placeholder="0" />
      </.field>
    </.fieldset>
    """
  end
end
