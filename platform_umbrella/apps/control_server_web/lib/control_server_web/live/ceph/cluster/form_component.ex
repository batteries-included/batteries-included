defmodule ControlServerWeb.Live.CephClusterFormComponent do
  use ControlServerWeb, :live_component

  import Phoenix.HTML.Form, only: [inputs_for: 2]
  import K8s.Resource.FieldAccessors, only: [name: 1]

  alias ControlServer.Rook
  alias KubeExt.KubeState

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :nodes, node_names())}
  end

  defp node_names, do: Enum.map(KubeState.nodes(), &name/1)

  @impl true
  def update(%{ceph_cluster: ceph_cluster} = assigns, socket) do
    changeset = Rook.change_ceph_cluster(ceph_cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:save_info, fn -> "ceph_cluster:save" end)
     |> assign(:changeset, changeset)
     |> assign(:num_mgr, ceph_cluster.num_mgr)
     |> assign(:num_mon, ceph_cluster.num_mon)}
  end

  @impl true
  def handle_event("validate", %{"ceph_cluster" => ceph_cluster_params}, socket) do
    changeset =
      socket.assigns.ceph_cluster
      |> Rook.change_ceph_cluster(ceph_cluster_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:num_mgr, Map.get(ceph_cluster_params, "num_mgr", 0))
     |> assign(:num_mon, Map.get(ceph_cluster_params, "num_mon", 0))}
  end

  def handle_event("save", %{"ceph_cluster" => ceph_cluster_params}, socket) do
    save_ceph_cluster(socket, socket.assigns.action, ceph_cluster_params)
  end

  def handle_event(
        "add_node",
        _,
        %{assigns: %{changeset: changeset, ceph_cluster: ceph_cluster}} = socket
      ) do
    nodes =
      changeset.changes
      |> Map.get(:nodes, ceph_cluster.nodes || [])
      |> Enum.concat([
        %ControlServer.Rook.CephStorageNode{name: "", device_filter: "/dev/sd?"}
      ])

    {:noreply, assign(socket, changeset: Ecto.Changeset.put_embed(changeset, :nodes, nodes))}
  end

  defp save_ceph_cluster(socket, :edit, ceph_cluster_params) do
    case Rook.update_ceph_cluster(socket.assigns.ceph_cluster, ceph_cluster_params) do
      {:ok, updated_ceph_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ceph cluster updated successfully")
         |> send_info(socket.assigns.save_target, updated_ceph_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_ceph_cluster(socket, :new, ceph_cluster_params) do
    case Rook.create_ceph_cluster(ceph_cluster_params) do
      {:ok, updated_ceph_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ceph cluster created successfully")
         |> send_info(socket.assigns.save_target, updated_ceph_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp send_info(socket, nil, _cluster), do: {:noreply, socket}

  defp send_info(socket, target, cluster) do
    send(target, {socket.assigns.save_info, %{"ceph_cluster" => cluster}})
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@changeset}
        id="ceph_cluster-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :name}} placeholder="Name" wrapper_class="form-control w-full col-span-2" />

        <.input min={1} max={5} type="range" field={{f, :num_mon}} placeholder="Number of Monitors" />
        <.labeled_definition title="Number of Monitors" contents={@num_mon} />

        <.input min={1} max={5} type="range" field={{f, :num_mgr}} placeholder="Number of MGR's" />
        <.labeled_definition title="Number of MGR daemons" contents={@num_mgr} />
        <.input
          field={{f, :data_dir_host_path}}
          placeholder="Data Dir Path (on Host)"
          wrapper_class="form-control w-full col-span-2"
        />

        <%= for node_form <- inputs_for(f, :nodes) do %>
          <.input field={{node_form, :name}} type="select">
            <:option value="" hidden={true}>Select a host</:option>
            <:option :for={node <- @nodes} value={node}>
              <%= node %>
            </:option>
          </.input>
          <.input field={{node_form, :device_filter}} placeholder="Device Filter" />
        <% end %>

        <div class="sm:col-span-1">
          <.link phx-click="add_node" phx-target={@myself}>Add Node</.link>
        </div>

        <:actions>
          <.button type="submit" phx-disable-with="Saving…" class="w-full">
            Save
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
