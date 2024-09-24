defmodule ControlServerWeb.Containers.ContainerModal do
  @moduledoc false

  use ControlServerWeb, :live_component

  alias CommonCore.Containers.Container
  alias CommonCore.Ecto.Validations
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign_new(socket, :target, fn -> nil end)}
  end

  @impl Phoenix.LiveComponent
  def update(
        %{container: container, idx: idx, container_field_name: cfn, update_func: update_func, id: id} = _assigns,
        socket
      ) do
    {:ok,
     socket
     |> assign_id(id)
     |> assign_idx(idx)
     |> assign_container(container)
     |> assign_container_field_name(cfn)
     |> assign_changeset(Container.changeset(container, %{}))
     |> assign_update_func(update_func)}
  end

  defp assign_id(socket, id) do
    assign(socket, id: id)
  end

  defp assign_idx(socket, idx) do
    assign(socket, idx: idx)
  end

  defp assign_container(socket, container) do
    assign(socket, container: container)
  end

  defp assign_container_field_name(socket, cfn) do
    assign(socket, container_field_name: cfn)
  end

  defp assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  defp assign_update_func(socket, update_func) do
    assign(socket, update_func: update_func)
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel", _, %{assigns: %{update_func: update_func, container_field_name: cfn}} = socket) do
    update_func.(nil, nil, cfn)
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_container", %{"container" => params}, socket) do
    changeset =
      socket.assigns.container
      |> Container.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_changeset(socket, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "save_container",
        %{"container" => params},
        %{assigns: %{container: container, idx: idx, container_field_name: cfn, update_func: update_func}} = socket
      ) do
    # Create a new changeset for the container
    changeset =
      container
      |> Container.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      # Get the resulting container from the changeset
      container = Changeset.apply_changes(changeset)
      update_func.(container, idx, cfn)
    end

    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event("add_arg", _params, socket) do
    changeset = Validations.add_item_to_list(socket.assigns.form.source, :args)
    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event("remove_arg", %{"index" => index}, socket) do
    changeset = Validations.remove_item_from_list(socket.assigns.form.source, :args, index)
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
        <.modal show size="lg" id={"#{@id}-modal"} on_cancel={JS.push("cancel", target: @myself)}>
          <:title>Container</:title>

          <.flex column>
            <.input label="Name" field={@form[:name]} autofocus placeholder="Name" />
            <.input label="Image" field={@form[:image]} placeholder="Image" />
            <.input label="Path (optional)" field={@form[:path]} placeholder="/bin/true" />

            <.input_list
              :let={field}
              field={@form[:args]}
              label="Arguments"
              add_label="Add argument"
              add_click="add_arg"
              remove_click="remove_arg"
              phx_target={@myself}
            >
              <.input field={field} />
            </.input_list>
          </.flex>

          <:actions cancel="Cancel">
            <.button variant="primary" type="submit" phx-disable-with="Saving...">Save</.button>
          </:actions>
        </.modal>
      </.form>
    </div>
    """
  end
end
