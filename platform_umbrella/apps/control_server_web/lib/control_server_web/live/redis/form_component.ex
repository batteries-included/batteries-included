defmodule ControlServerWeb.Live.Redis.FormComponent do
  use ControlServerWeb, :live_component

  alias ControlServer.Redis
  alias CommonCore.Redis.FailoverCluster

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "failover_cluster:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl Phoenix.LiveComponent
  def update(%{failover_cluster: failover_cluster} = assigns, socket) do
    changeset = Redis.change_failover_cluster(failover_cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:sentinel_name, "rfs-#{failover_cluster.name}")
     |> assign(:num_instances, failover_cluster.num_redis_instances)
     |> assign(:num_sentinel_instances, failover_cluster.num_sentinel_instances)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"failover_cluster" => failover_cluster_params}, socket) do
    {changeset, data} = FailoverCluster.validate(failover_cluster_params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:num_instances, data.num_redis_instances)
     |> assign(:num_sentinel_instances, data.num_sentinel_instances)
     |> assign(:sentinel_name, "rfs-#{data.name}")}
  end

  def handle_event("save", %{"failover_cluster" => failover_cluster_params}, socket) do
    save_failover_cluster(socket, socket.assigns.action, failover_cluster_params)
  end

  defp save_failover_cluster(socket, :edit, failover_cluster_params) do
    case Redis.update_failover_cluster(socket.assigns.failover_cluster, failover_cluster_params) do
      {:ok, failover_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Failover cluster updated successfully")
         |> send_info(socket.assigns.save_target, failover_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_failover_cluster(socket, :new, failover_cluster_params) do
    case Redis.create_failover_cluster(failover_cluster_params) do
      {:ok, failover_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Failover cluster created successfully")
         |> send_info(socket.assigns.save_target, failover_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp send_info(socket, nil, _failover_cluster), do: {:noreply, socket}

  defp send_info(socket, target, failover_cluster) do
    send(target, {socket.assigns.save_info, %{"failover_cluster" => failover_cluster}})
    socket
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@changeset}
        id="failover_cluster-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={{f, :name}} placeholder="Name" />
        <.labeled_definition title="Service Name" contents={@sentinel_name} />
        <.input
          min={1}
          max={5}
          type="range"
          field={{f, :num_redis_instances}}
          placeholder="Number of Instances"
        />
        <.labeled_definition title="Number of Instances" contents={@num_instances} />
        <.input
          min={1}
          max={5}
          type="range"
          field={{f, :num_sentinel_instances}}
          placeholder="Number of Instances"
        />
        <.labeled_definition title="Number of Sentinel Instances" contents={@num_sentinel_instances} />
        <:actions>
          <.button type="submit" phx-disable-with="Saving…">
            Save
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
