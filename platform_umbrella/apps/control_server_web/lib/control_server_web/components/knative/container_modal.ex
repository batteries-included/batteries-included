defmodule ControlServerWeb.Knative.ContainerModal do
  @moduledoc false

  use ControlServerWeb, :live_component

  alias CommonCore.Services.Container
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
      <.form
        for={@form}
        id="container-form"
        phx-change="validate_container"
        phx-submit="save_container"
        phx-target={@myself}
      >
        <.modal show id={"#{@id}-modal"} on_cancel={JS.push("cancel", target: @myself)}>
          <:title>Container</:title>

          <.grid columns={[sm: 1, lg: 2]}>
            <.input label="Name" field={@form[:name]} autofocus placeholder="Name" />
            <.input label="Image" field={@form[:image]} placeholder="Image" />
            <div class="col-span-2">
              <.input
                name="container[command][]"
                value={(@form.data.command || []) |> List.first(nil)}
                label="Command"
                placeholder="/bin/true"
              />
            </div>
          </.grid>

          <:actions cancel="Cancel">
            <.button variant="primary" type="submit" phx-disable-with="Saving...">Save</.button>
          </:actions>
        </.modal>
      </.form>
    </div>
    """
  end
end
