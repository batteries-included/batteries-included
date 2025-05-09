defmodule ControlServerWeb.Containers.EnvValuePanel do
  @moduledoc false
  use ControlServerWeb, :html

  import ControlServerWeb.Containers.EnvValueTable

  attr :class, :any, default: nil
  attr :editable, :boolean, default: false
  attr :env_values, :list, default: []
  attr :target, :any, default: nil
  attr :variant, :string, default: "gray"

  def env_var_panel(%{editable: false} = assigns) do
    ~H"""
    <.panel title="Environment Variables" class={@class} variant={@variant}>
      <.env_var_table env_values={@env_values} />
    </.panel>
    """
  end

  def env_var_panel(%{editable: true} = assigns) do
    ~H"""
    <.panel title="Environment Variables" class={@class} variant={@variant}>
      <:menu>
        <.button icon={:plus} phx-click="new_env_value" phx-target={@target}>
          Add Variable
        </.button>
      </:menu>

      <.env_var_table env_values={@env_values}>
        <:action :let={{ev, idx}}>
          <.button
            variant="minimal"
            icon={:x_mark}
            id={"delete_env_value_" <> String.replace(ev.name, " ", "")}
            phx-click="del:env_value"
            phx-value-idx={idx}
            phx-target={@target}
          />

          <.tooltip target_id={"delete_env_value_" <> String.replace(ev.name, " ", "")}>
            Remove
          </.tooltip>

          <.button
            variant="minimal"
            icon={:pencil}
            id={"edit_env_value_" <> String.replace(ev.name, " ", "")}
            phx-click="edit:env_value"
            phx-value-idx={idx}
            phx-target={@target}
          />

          <.tooltip target_id={"edit_env_value_" <> String.replace(ev.name, " ", "")}>
            Edit
          </.tooltip>
        </:action>
      </.env_var_table>
    </.panel>
    """
  end
end
