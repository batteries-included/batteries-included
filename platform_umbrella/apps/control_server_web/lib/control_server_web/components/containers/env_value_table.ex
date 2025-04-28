defmodule ControlServerWeb.Containers.EnvValueTable do
  @moduledoc false

  use ControlServerWeb, :html

  attr :id, :string, default: "env-var-table"
  attr :env_values, :list, required: true
  attr :opts, :list, default: []

  slot :action, doc: "the slot for showing user actions in the last table column"

  def env_var_table(assigns) do
    ~H"""
    <.table id={@id} rows={Enum.with_index(@env_values)} opts={@opts}>
      <:col :let={{ev, _idx}} label="Name">{ev.name}</:col>
      <:col :let={{ev, _idx}} label="Value"><.env_value_value env_value={ev} /></:col>
      <:action :let={{ev, idx}} :if={@action != []}>
        {render_slot(@action, {ev, idx})}
      </:action>
    </.table>
    """
  end

  defp env_value_value(%{env_value: %{source_type: :value}} = assigns) do
    ~H"""
    {CommonUI.TextHelpers.obfuscate(@env_value.value)}
    """
  end

  defp env_value_value(%{env_value: %{source_type: _}} = assigns) do
    ~H"""
    <.truncate_tooltip value={"From #{@env_value.source_name}"} />
    """
  end
end
