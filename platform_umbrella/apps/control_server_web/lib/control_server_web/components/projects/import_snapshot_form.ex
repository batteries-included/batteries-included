defmodule ControlServerWeb.Projects.ImportSnapshotForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.ProjectsSubcomponents

  alias CommonCore.Projects.ProjectSnapshot
  alias KubeServices.ET.HomeBaseClient

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{data: data} = assigns, socket) do
    selected_id = get_in(data, [ControlServerWeb.Projects.ImportSelectSnapshotForm, "selected_snapshot_id"])

    {:ok,
     socket
     |> assign(:selected_snapshot_id, selected_id)
     |> assign(assigns)
     |> assign_snapshot()}
  end

  defp assign_snapshot(%{assigns: %{selected_snapshot_id: snap_id}} = socket) when snap_id != nil and snap_id != "" do
    {:ok, snapshot} = HomeBaseClient.get_snapshot(snap_id)
    changeset = ProjectSnapshot.changeset(snapshot, %{})
    form = to_form(changeset)
    socket |> assign(:snapshot, snapshot) |> assign(:form, form)
  end

  defp assign_snapshot(socket) do
    socket |> assign(:snapshot, nil) |> assign(:form, nil)
  end

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.subform title="Import Snapshot">
        <.h3>{@selected_snapshot_id}</.h3>
        <.form
          :if={@form != nil && @snapshot != nil}
          for={@form}
          id={"form_#{@id}"}
          phx-change="validate"
          phx-submit="submit"
        >
          {@snapshot.name}
        </.form>
      </.subform>
    </div>
    """
  end
end
