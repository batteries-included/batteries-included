defmodule ControlServerWeb.OllamaFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Defaults.GPU
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
  attr :projects, :list, default: []

  def details_form(assigns) do
    ~H"""
    <.fieldset class={@class}>
      <.field>
        <:label>Size</:label>
        <.input
          field={@form[:virtual_size]}
          type="select"
          placeholder="Choose a size"
          options={ModelInstance.preset_options_for_select(@form[:model].value)}
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
        <.input
          field={@form[:node_type]}
          type="select"
          label="GPU"
          placeholder="None"
          options={GPU.node_types_for_select()}
        />
      </.field>
      <.field :if={gpu_node_type?(@form[:node_type].value)}>
        <:label>GPU Count</:label>
        <.input field={@form[:gpu_count]} type="number" placeholder="0" />
      </.field>

      <.field>
        <:label>Project</:label>
        <.input
          type="select"
          field={@form[:project_id]}
          placeholder="No Project"
          placeholder_selectable={true}
          options={Enum.map(@projects, &{&1.name, &1.id})}
        />
      </.field>
    </.fieldset>
    """
  end

  defp gpu_node_type?(node_type) when is_binary(node_type), do: node_type |> String.to_existing_atom() |> gpu_node_type?()

  defp gpu_node_type?(node_type), do: node_type in GPU.node_types_with_gpus()
end
