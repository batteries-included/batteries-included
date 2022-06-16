defmodule ControlServerWeb.Live.Postgres.FormComponent do
  use ControlServerWeb, :live_component

  use CommonUI

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias CommonUI.Form

  require Logger

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "cluster:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl true
  def update(%{cluster: cluster} = assigns, socket) do
    changeset = Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:full_name, Cluster.full_name(cluster))
     |> assign(:num_instances, cluster.num_instances)}
  end

  @impl true
  def handle_event("validate", %{"cluster" => params}, socket) do
    {changeset, data} = Cluster.validate(params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:full_name, Cluster.full_name(data))
     |> assign(:num_instances, data.num_instances)}
  end

  def handle_event("save", %{"cluster" => cluster_params}, socket) do
    save_cluster(socket, socket.assigns.action, cluster_params)
  end

  defp save_cluster(socket, :new, cluster_params) do
    case Postgres.create_cluster(cluster_params) do
      {:ok, new_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Postgres Cluster created successfully")
         |> send_info(socket.assigns.save_target, new_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_cluster(socket, :edit, cluster_params) do
    case Postgres.update_cluster(socket.assigns.cluster, cluster_params) do
      {:ok, updated_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Postgres Cluster updated successfully")
         |> send_info(socket.assigns.save_target, updated_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp send_info(socket, nil, _cluster), do: {:noreply, socket}

  defp send_info(socket, target, cluster) do
    send(target, {socket.assigns.save_info, %{"cluster" => cluster}})
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10">
      <.form
        let={f}
        for={@changeset}
        id="cluster-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <div class="grid grid-cols-1 mt-6 gap-y-6 gap-x-4 sm:grid-cols-2">
          <Form.text_input form={f} field={:name} placeholder="Name" />
          <div class="sm:col-span-1">
            <.labeled_definition title="Service Name" contents={@full_name} />
          </div>
          <Form.range_input
            min={1}
            max={5}
            form={f}
            field={:num_instances}
            placeholder="Number of Instances"
          />
          <div class="sm:col-span-1">
            <.labeled_definition title="Number of Instances" contents={@num_instances} />
          </div>
          <Form.text_input form={f} field={:storage_size} placeholder="Storage Size" />
        </div>
        <div class="grid grid-cols-1 mt-6 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.button type="submit" phx_disable_with="Saving…" class="sm:col-span-2">
            Save
          </.button>
        </div>
      </.form>
    </div>
    """
  end
end
