defmodule ControlServerWeb.Knative.EnvValuePanel do
  @moduledoc false
  use ControlServerWeb, :html

  defp env_value_value(%{env_value: %{source_type: :value}} = assigns) do
    ~H"""
    <%= @env_value.value %>
    """
  end

  defp env_value_value(%{env_value: %{source_type: _}} = assigns) do
    ~H"""
    <.truncate_tooltip value={"From #{@env_value.source_name}"} />
    """
  end

  attr(:editable, :boolean, default: false)
  attr(:env_values, :list, default: [])
  attr(:target, :any, default: nil)

  def env_var_panel(%{editable: false} = assigns) do
    ~H"""
    <.panel title="Environment Variables">
      <.table rows={@env_values}>
        <:col :let={ev} label="Name"><%= ev.name %></:col>
        <:col :let={ev} label="Value"><.env_value_value env_value={ev} /></:col>
      </.table>
    </.panel>
    """
  end

  def env_var_panel(%{editable: true} = assigns) do
    ~H"""
    <.panel title="Environment Variables" class="lg:col-span-2">
      <:menu>
        <.button icon={:plus} phx-click="new_env_value" phx-target={@target}>
          Variable
        </.button>
      </:menu>

      <.table rows={Enum.with_index(@env_values)}>
        <:col :let={{ev, _idx}} label="Name"><%= ev.name %></:col>
        <:col :let={{ev, _idx}} label="Value"><.env_value_value env_value={ev} /></:col>
        <:action :let={{ev, idx}}>
          <.action_icon
            to="/"
            icon={:x_mark}
            id={"delete_env_value_" <> String.replace(ev.name, " ", "")}
            phx-click="del:env_value"
            phx-value-idx={idx}
            tooltip="Remove"
            link_type="button"
            type="button"
            phx-target={@target}
          />

          <.action_icon
            to="/"
            icon={:pencil}
            id={"edit_env_value_" <> String.replace(ev.name, " ", "")}
            phx-click="edit:env_value"
            phx-value-idx={idx}
            tooltip="Edit"
            link_type="button"
            type="button"
            phx-target={@target}
          />
        </:action>
      </.table>
    </.panel>
    """
  end
end
