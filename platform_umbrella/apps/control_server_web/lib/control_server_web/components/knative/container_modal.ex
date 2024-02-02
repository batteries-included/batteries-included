defmodule ControlServerWeb.Knative.ContainerModal do
  @moduledoc false

  use ControlServerWeb, :live_component

  alias CommonCore.Knative.Container
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign_new(socket, :target, fn -> nil end)}
  end

  @impl Phoenix.LiveComponent
  def update(%{container: container, idx: idx} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset(Container.changeset(container, %{}))
     |> assign(idx: idx)}
  end

  defp assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_modal", _, socket) do
    ControlServerWeb.Live.Knative.FormComponent.update_container(nil, nil)
    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    ControlServerWeb.Live.Knative.FormComponent.update_container(nil, nil)
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_container", %{"container" => params}, socket) do
    changeset = Container.changeset(socket.assigns.container, params)
    {:noreply, assign_changeset(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save_container", %{"container" => params}, %{assigns: %{container: container, idx: idx}} = socket) do
    # Create a new changeset for the container
    changeset = Container.changeset(container, params)
    # Get the resulting container from the changeset
    container = Changeset.apply_changes(changeset)

    if changeset.valid? do
      ControlServerWeb.Live.Knative.FormComponent.update_container(container, idx)
    end

    {:noreply, assign_changeset(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <PC.modal id={"#{@id}-modal"} title="Container" close_modal_target={@myself}>
        <.form
          for={@form}
          id="container-form"
          phx-change="validate_container"
          phx-submit="save_container"
          phx-target={@myself}
        >
          <.grid columns={[sm: 1, lg: 2]}>
            <PC.field field={@form[:name]} autofocus placeholder="Name" />
            <PC.field field={@form[:image]} autofocus placeholder="Image" />
            <PC.field
              name="container[command][]"
              value={(@form.data.command || []) |> List.first(nil)}
              label="Command"
              autofocus
              placeholder="/bin/true"
              wrapper_class="col-span-2"
            />
            <.flex class="justify-end col-span-2">
              <.button phx-target={@myself} phx-click="cancel" type="button">
                Cancel
              </.button>
              <PC.button type="submit" phx-disable-with="Saving...">Save</PC.button>
            </.flex>
          </.grid>
        </.form>
      </PC.modal>
    </div>
    """
  end
end
