defmodule ControlServerWeb.PortPanel do
  @moduledoc false
  use ControlServerWeb, :html

  # defp env_value_value(%{env_value: %{source_type: :value}} = assigns) do
  #   ~H"""
  #   <%= @env_value.value %>
  #   """
  # end
  #
  # defp env_value_value(%{env_value: %{source_type: _}} = assigns) do
  #   ~H"""
  #   <.truncate_tooltip value={"From #{@env_value.source_name}"} />
  #   """
  # end

  attr :class, :any, default: nil
  attr :editable, :boolean, default: false
  attr :ports, :list, default: []
  attr :target, :any, default: nil
  attr :id, :string, default: "ports_panel"

  def port_panel(%{editable: false} = assigns) do
    ~H"""
    <.panel title="Ports" class={@class} id={@id}>
      <.table id="ports-table" rows={@ports}>
        <:col :let={p} label="Name">{p.name}</:col>
        <:col :let={p} label="Port">{p.number}</:col>
        <:col :let={p} label="Protocol">{p.protocol}</:col>
      </.table>
    </.panel>
    """
  end

  def port_panel(%{editable: true} = assigns) do
    ~H"""
    <.panel title="Ports" class={@class} id={@id}>
      <:menu>
        <.button icon={:plus} phx-click="new_port" phx-target={@target}>
          Add Port
        </.button>
      </:menu>

      <.table id="ports-table" rows={Enum.with_index(@ports)}>
        <:col :let={{p, _idx}} label="Name">{p.name}</:col>
        <:col :let={{p, _idx}} label="Port">{p.number}</:col>
        <:col :let={{p, _idx}} label="Protocol">{p.protocol}</:col>
        <:action :let={{p, idx}}>
          <.button
            variant="minimal"
            icon={:x_mark}
            id={"delete_port_" <> String.replace(p.name, " ", "")}
            phx-click="del:port"
            phx-value-idx={idx}
            phx-target={@target}
          />

          <.tooltip target_id={"delete_port_" <> String.replace(p.name, " ", "")}>
            Remove
          </.tooltip>

          <.button
            variant="minimal"
            icon={:pencil}
            id={"edit_port_" <> String.replace(p.name, " ", "")}
            phx-click="edit:port"
            phx-value-idx={idx}
            phx-target={@target}
          />

          <.tooltip target_id={"edit_port_" <> String.replace(p.name, " ", "")}>
            Edit
          </.tooltip>
        </:action>
      </.table>
    </.panel>
    """
  end
end
