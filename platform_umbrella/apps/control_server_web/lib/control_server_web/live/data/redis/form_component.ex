defmodule ControlServerWeb.Live.Redis.FormComponent do
  use ControlServerWeb, :live_component

  alias ControlServer.Redis
  alias ControlServer.Redis.FailoverCluster

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "failover_cluster:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl true
  def update(%{failover_cluster: failover_cluster} = assigns, socket) do
    changeset = Redis.change_failover_cluster(failover_cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"failover_cluster" => failover_cluster_params}, socket) do
    {changeset, _data} = FailoverCluster.validate(failover_cluster_params)

    {:noreply, assign(socket, :changeset, changeset)}
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

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form
        let={f}
        for={@changeset}
        id="failover_cluster-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= label(f, :name) %>
        <%= text_input(f, :name) %>
        <%= error_tag(f, :name) %>

        <%= label(f, :num_sentinel_instances) %>
        <%= number_input(f, :num_sentinel_instances) %>
        <%= error_tag(f, :num_sentinel_instances) %>

        <%= label(f, :num_redis_instances) %>
        <%= number_input(f, :num_redis_instances) %>
        <%= error_tag(f, :num_redis_instances) %>

        <%= label(f, :memory_request) %>
        <%= text_input(f, :memory_request) %>
        <%= error_tag(f, :memory_request) %>

        <div>
          <%= submit("Save", phx_disable_with: "Saving...") %>
        </div>
      </.form>
    </div>
    """
  end
end
