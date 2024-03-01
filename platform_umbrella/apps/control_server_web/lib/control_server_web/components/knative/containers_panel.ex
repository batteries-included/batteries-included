defmodule ControlServerWeb.Knative.ContainersPanel do
  @moduledoc false
  use ControlServerWeb, :html

  attr :containers, :list, default: []
  attr :init_containers, :list, default: []
  attr :target, :any, default: nil

  def containers_panel(assigns) do
    ~H"""
    <.panel title="Containers">
      <:menu>
        <.button icon={:plus} phx-click="new_container" phx-target={@target}>
          Container
        </.button>
      </:menu>
      <.table rows={Enum.with_index(@containers ++ @init_containers)}>
        <:col :let={{c, _idx}} label="Name"><%= c.name %></:col>
        <:col :let={{c, _idx}} label="Image"><%= c.image %></:col>
        <:col :let={{_c, idx}} label="Init Container">
          <%= if idx > length(@containers), do: "Yes", else: "No" %>
        </:col>

        <:action :let={{c, idx}}>
          <.action_icon
            to="/"
            icon={:x_mark}
            id={"delete_container_" <> String.replace(c.name, " ", "")}
            phx-click="del:container"
            tooltip="Remove"
            link_type="button"
            type="button"
            phx-target={@target}
            phx-value-idx={if idx > length(@containers), do: idx - length(@containers), else: idx}
            phx-value-is-init={if idx > length(@containers), do: "true", else: "false"}
          />

          <.action_icon
            to="/"
            icon={:pencil}
            id={"edit_container_" <> String.replace(c.name, " ", "")}
            tooltip="Edit"
            link_type="button"
            type="button"
            phx-target={@target}
            phx-click="edit:container"
            phx-value-idx={if idx > length(@containers), do: idx - length(@containers), else: idx}
            phx-value-is-init={if idx > length(@containers), do: "true", else: "false"}
          />
        </:action>
      </.table>
    </.panel>
    """
  end
end
