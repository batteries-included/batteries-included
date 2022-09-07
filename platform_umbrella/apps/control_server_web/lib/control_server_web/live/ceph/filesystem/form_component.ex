defmodule ControlServerWeb.Live.CephFilesystemFormComponent do
  use ControlServerWeb, :live_component

  alias ControlServer.Rook
  alias CommonUI.Form

  @impl true
  def update(%{ceph_filesystem: ceph_filesystem} = assigns, socket) do
    changeset = Rook.change_ceph_filesystem(ceph_filesystem)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:save_info, fn -> "ceph_filesystem:save" end)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"ceph_filesystem" => ceph_filesystem_params}, socket) do
    changeset =
      socket.assigns.ceph_filesystem
      |> Rook.change_ceph_filesystem(ceph_filesystem_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"ceph_filesystem" => ceph_filesystem_params}, socket) do
    save_ceph_filesystem(socket, socket.assigns.action, ceph_filesystem_params)
  end

  defp save_ceph_filesystem(socket, :edit, ceph_filesystem_params) do
    case Rook.update_ceph_filesystem(socket.assigns.ceph_filesystem, ceph_filesystem_params) do
      {:ok, updated_ceph_filesystem} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ceph cluster updated successfully")
         |> send_info(socket.assigns.save_target, updated_ceph_filesystem)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_ceph_filesystem(socket, :new, ceph_filesystem_params) do
    case Rook.create_ceph_filesystem(ceph_filesystem_params) do
      {:ok, updated_ceph_filesystem} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ceph cluster created successfully")
         |> send_info(socket.assigns.save_target, updated_ceph_filesystem)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp send_info(socket, nil, _cluster), do: {:noreply, socket}

  defp send_info(socket, target, cluster) do
    send(target, {socket.assigns.save_info, %{"ceph_filesystem" => cluster}})
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10">
      <.form
        let={f}
        for={@changeset}
        id="ceph_filesystem-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 mt-6 gap-y-6 gap-x-4 sm:grid-cols-2">
          <Form.text_input form={f} field={:name} placeholder="Name" />
          <Form.switch_input form={f} field={:include_erasure_encoded} />

          <div class="mt-6 col-span-2">
            <.button type="submit" phx_disable_with="Saving…" class="w-full">
              Save
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
