defmodule ControlServerWeb.Containers.ContainersPanel do
  @moduledoc false
  use ControlServerWeb, :html

  attr :containers, :list, default: []
  attr :init_containers, :list, default: []
  attr :target, :any, default: nil
  attr :id, :string, default: "container-panel"
  attr :title, :string, default: "Containers"

  def containers_panel(assigns) do
    ~H"""
    <.panel title={@title} id={@id}>
      <:menu>
        <.button icon={:plus} phx-click="new_container" phx-target={@target} phx-value-id={@id}>
          Add Container
        </.button>
      </:menu>
      <.table id={"containers-table-#{@id}"} rows={Enum.with_index(@containers ++ @init_containers)}>
        <:col :let={{c, _idx}} label="Name">{c.name}</:col>
        <:col :let={{c, _idx}} label="Image"><pre>{c.image}</pre></:col>

        <:action :let={{c, idx}}>
          <.button
            variant="minimal"
            icon={:x_mark}
            id={@id <> "_delete_container_" <> String.replace(c.name, " ", "")}
            phx-click="del:container"
            phx-target={@target}
            phx-value-idx={if idx > length(@containers), do: idx - length(@containers), else: idx}
            phx-value-id={@id}
          />

          <.tooltip target_id={@id <> "_delete_container_" <> String.replace(c.name, " ", "")}>
            Remove
          </.tooltip>

          <.button
            variant="minimal"
            icon={:pencil}
            id={@id <> "_edit_container_" <> String.replace(c.name, " ", "")}
            phx-target={@target}
            phx-click="edit:container"
            phx-value-idx={if idx > length(@containers), do: idx - length(@containers), else: idx}
            phx-value-id={@id}
          />

          <.tooltip target_id={@id<> "_edit_container_" <> String.replace(c.name, " ", "")}>
            Edit
          </.tooltip>
        </:action>
      </.table>
    </.panel>
    """
  end
end
