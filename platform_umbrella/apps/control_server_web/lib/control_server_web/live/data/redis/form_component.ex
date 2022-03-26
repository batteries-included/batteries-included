defmodule ControlServerWeb.Live.Redis.FormComponent do
  use ControlServerWeb, :live_component

  import CommonUI

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
     |> assign(:sentinel_name, "rfs-#{failover_cluster.name}")
     |> assign(:num_instances, failover_cluster.num_redis_instances)
     |> assign(:num_sentinel_instances, failover_cluster.num_sentinel_instances)
     |> assign(:changeset, changeset)}
  end

  @impl true
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10">
      <.form
        let={f}
        for={@changeset}
        id="failover_cluster-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 mt-6 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.form_field
            type="text_input"
            form={f}
            field={:name}
            placeholder="Name"
            wrapper_class="sm:col-span-1"
          />
          <div class="sm:col-span-1">
            <.labeled_definition title={"Service Name"} contents={@sentinel_name} />
          </div>
          <.form_field
            type="range_input"
            input_opts={%{min: 1, max: 5}}
            form={f}
            field={:num_redis_instances}
            placeholder="Number of Instances"
            wrapper_class="sm:col-span-1"
          />
          <div class="sm:col-span-1">
            <.labeled_definition title={"Number of Instances"} contents={@num_instances} />
          </div>

          <.form_field
            type="range_input"
            input_opts={%{min: 0, max: 5}}
            form={f}
            field={:num_sentinel_instances}
            placeholder="Number of Instances"
            wrapper_class="sm:col-span-1"
          />
          <div class="sm:col-span-1">
            <.labeled_definition
              title={"Number of Sentinel Instances"}
              contents={@num_sentinel_instances}
            />
          </div>
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
