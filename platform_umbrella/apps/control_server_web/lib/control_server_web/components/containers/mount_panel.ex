defmodule ControlServerWeb.Containers.MountPanel do
  @moduledoc false
  use ControlServerWeb, :html

  attr :class, :any, default: nil
  attr :editable, :boolean, default: false
  attr :mounts, :list, default: []
  attr :target, :any, default: nil
  attr :variant, :string, default: "gray"

  def mount_panel(%{editable: false} = assigns) do
    ~H"""
    <.panel title="Volume Mounts" class={@class} variant={@variant}>
      <.mount_table mounts={@mounts} />
    </.panel>
    """
  end

  def mount_panel(%{editable: true} = assigns) do
    ~H"""
    <.panel title="Volume Mounts" class={@class} variant={@variant}>
      <:menu>
        <.button icon={:plus} phx-click="new_mount" phx-target={@target}>
          Add Volume Mount
        </.button>
      </:menu>

      <.mount_table mounts={@mounts}>
        <:action :let={{_, idx}}>
          <.button
            variant="minimal"
            icon={:x_mark}
            id={"delete_mount_#{idx}"}
            phx-click="del:mount"
            phx-value-idx={idx}
            phx-target={@target}
          />

          <.tooltip target_id={"delete_mount_#{idx}"}>
            Remove
          </.tooltip>

          <.button
            variant="minimal"
            icon={:pencil}
            id={"edit_mount_#{idx}"}
            phx-click="edit:mount"
            phx-value-idx={idx}
            phx-target={@target}
          />

          <.tooltip target_id={"edit_mount_#{idx}"}>
            Edit
          </.tooltip>
        </:action>
      </.mount_table>
    </.panel>
    """
  end

  attr :id, :string, default: "mounts-table"
  attr :mounts, :list, required: true
  attr :opts, :list, default: []

  slot :action, doc: "the slot for showing user actions in the last table column"

  def mount_table(assigns) do
    ~H"""
    <.table id={@id} rows={Enum.with_index(@mounts)} opts={@opts}>
      <:col :let={{m, _idx}} label="Volume Name">{m.volume_name}</:col>
      <:col :let={{m, _idx}} label="Mount Path">{m.mount_path}</:col>
      <:col :let={{m, _idx}} label="Read Only">{m.read_only}</:col>
      <:action :let={{m, idx}} :if={@action != []}>
        {render_slot(@action, {m, idx})}
      </:action>
    </.table>
    """
  end
end
