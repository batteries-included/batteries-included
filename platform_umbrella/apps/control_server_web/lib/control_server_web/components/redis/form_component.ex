defmodule ControlServerWeb.Live.Redis.FormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Redis.FailoverCluster
  alias CommonCore.Util.Integer
  alias CommonCore.Util.Memory
  alias ControlServer.Redis

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="failover_cluster-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header title={@title} back_link={~p"/redis"}>
          <.button variant="dark" type="submit" phx-disable-with="Saving…">
            Save Redis Cluster
          </.button>
        </.page_header>

        <.panel>
          <.grid columns={[sm: 1, lg: 2]} class="items-center">
            <.input field={@form[:name]} label="Name" disabled={@action == :edit} />
            <.input
              field={@form[:virtual_size]}
              type="select"
              label="Size"
              placeholder="Choose a size"
              options={FailoverCluster.preset_options_for_select()}
            />
          </.grid>
          <.data_horizontal_bolded
            :if={@form[:virtual_size].value != "custom"}
            class="mt-3 mb-5"
            data={[
              {"Memory limits:", @form[:memory_limits].value |> Memory.format_bytes(true)},
              {"CPU limits:", @form[:cpu_limits].value}
            ]}
          />
          <!-- Memory limits -->
          <.flex :if={@form[:virtual_size].value == "custom"} column class="pt-4">
            <.h3>Running Limits</.h3>
            <.grid columns={[sm: 1, md: 2, xl: 4]}>
              <.input field={@form[:cpu_requested]} label="CPU Requested" />
              <.input field={@form[:cpu_limits]} label="CPU Limits" />
              <.input field={@form[:memory_requested]} label="Memory Requested" />
              <.input field={@form[:memory_limits]} label="Memory Limits" />
            </.grid>
          </.flex>
          <!-- Number of instances -->
          <.grid columns={[sm: 1, lg: 2]} class="items-center">
            <.h5>Number of instances</.h5>
            <.input field={@form[:num_redis_instances]} type="range" min="1" max="3" step="1" />
          </.grid>
          <.grid
            :if={@form[:num_redis_instances].value |> Integer.to_integer() > 1}
            columns={[sm: 1, lg: 2]}
            class="items-center"
          >
            <.h5>Number of sentinel instances</.h5>
            <.input field={@form[:num_sentinel_instances]} type="range" min="1" max="3" step="1" />
          </.grid>
        </.panel>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{failover_cluster: failover_cluster} = assigns, socket) do
    changeset = Redis.change_failover_cluster(failover_cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"failover_cluster" => failover_cluster_params}, socket) do
    changeset =
      socket.assigns.failover_cluster
      |> Redis.change_failover_cluster(failover_cluster_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"failover_cluster" => failover_cluster_params}, socket) do
    save_failover_cluster(socket, socket.assigns.action, failover_cluster_params)
  end

  defp save_failover_cluster(socket, :edit, failover_cluster_params) do
    case Redis.update_failover_cluster(socket.assigns.failover_cluster, failover_cluster_params) do
      {:ok, failover_cluster} ->
        notify_parent({:saved, failover_cluster})

        {:noreply,
         socket
         |> put_flash(:info, "Failover cluster updated successfully")
         |> push_navigate(to: ~p"/redis/#{failover_cluster.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_failover_cluster(socket, :new, failover_cluster_params) do
    case Redis.create_failover_cluster(failover_cluster_params) do
      {:ok, failover_cluster} ->
        notify_parent({:saved, failover_cluster})

        {:noreply,
         socket
         |> put_flash(:info, "Failover cluster created successfully")
         |> push_navigate(to: ~p"/redis/#{failover_cluster.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
