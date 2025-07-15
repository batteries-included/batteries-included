defmodule ControlServerWeb.Containers.VolumePanel do
  @moduledoc false
  use ControlServerWeb, :html

  attr :class, :any, default: nil
  attr :editable, :boolean, default: false
  attr :volumes, :list, default: []
  attr :target, :any, default: nil
  attr :variant, :string, default: "gray"
  attr :id, :string, default: "volume_panel"

  def volume_panel(%{editable: false} = assigns) do
    ~H"""
    <.panel title="Volumes" class={@class} variant={@variant} id={@id}>
      <.volumes_table volumes={@volumes} />
    </.panel>
    """
  end

  def volume_panel(%{editable: true} = assigns) do
    ~H"""
    <.panel title="Volumes" class={@class} variant={@variant} id={@id}>
      <:menu>
        <.button icon={:plus} phx-click="new_volume" phx-target={@target}>
          Add Volume
        </.button>
      </:menu>

      <.volumes_table volumes={@volumes}>
        <:action :let={{v, idx}}>
          <.button
            variant="minimal"
            icon={:x_mark}
            id={"delete_volume_" <> String.replace(v.name, " ", "")}
            phx-click="del:volume"
            phx-value-idx={idx}
            phx-target={@target}
          />

          <.tooltip target_id={"delete_volume_" <> String.replace(v.name, " ", "")}>
            Remove
          </.tooltip>

          <.button
            variant="minimal"
            icon={:pencil}
            id={"edit_volume_" <> String.replace(v.name, " ", "")}
            phx-click="edit:volume"
            phx-value-idx={idx}
            phx-target={@target}
          />

          <.tooltip target_id={"edit_volume_" <> String.replace(v.name, " ", "")}>
            Edit
          </.tooltip>
        </:action>
      </.volumes_table>
    </.panel>
    """
  end

  attr :id, :string, default: "volume-table"
  attr :volumes, :list, required: true
  attr :opts, :list, default: []

  slot :action, doc: "the slot for showing user actions in the last table column"

  def volumes_table(assigns) do
    ~H"""
    <.table id={@id} rows={Enum.with_index(@volumes)} opts={@opts}>
      <:col :let={{v, _idx}} label="Name">{v.name}</:col>
      <:col :let={{v, _idx}} label="Type">{v.type}</:col>
      <:action :let={{v, idx}} :if={@action != []}>
        {render_slot(@action, {v, idx})}
      </:action>
    </.table>
    """
  end
end
