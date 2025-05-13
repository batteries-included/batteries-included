defmodule ControlServerWeb.Projects.ImportForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias KubeServices.ET.HomeBaseClient

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    form = assigns |> Map.get(:data, %{}) |> to_form()

    snapshots = HomeBaseClient.list_snapshots()

    {:ok, socket |> assign(:form, form) |> assign(:snapshots, snapshots) |> assign(assigns)}
  end

  def render(assigns) do
    ~H"""
    <div class="contents" id={"contents_import_#{@id}"}>
      <.form
        id={@id}
        for={@form}
        class={@class}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:search]}
          icon={:magnifying_glass}
          placeholder="Type to search..."
          debounce="10"
        /> Test
      </.form>
    </div>
    """
  end
end
