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
        <.page_header title={@title} back_button={%{link_type: "live_redirect", to: ~p"/redis"}}>
          <:menu>
            <.button variant="dark" phx-disable-with="Saving…">Save Redis Cluster</.button>
          </:menu>
        </.page_header>

        <.panel>
          <.grid columns={[sm: 1, lg: 2]} class="items-center">
            <PC.field field={@form[:name]} label="Name" disabled={@action == :edit} />
            <PC.field
              field={@form[:virtual_size]}
              type="select"
              label="Size"
              prompt="Choose a size"
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
            <PC.h3>Running Limits</PC.h3>
            <.grid columns={[sm: 1, md: 2, xl: 4]}>
              <PC.field field={@form[:cpu_requested]} label="CPU Requested" />
              <PC.field field={@form[:cpu_limits]} label="CPU Limits" />
              <PC.field field={@form[:memory_requested]} label="Memory Requested" />
              <PC.field field={@form[:memory_limits]} label="Memory Limits" />
            </.grid>
          </.flex>
          <!-- Number of instances -->
          <.grid columns={[sm: 1, lg: 2]} class="items-center">
            <.flex>
              <.h5>Number of instances</.h5>
              <div class="font-bold text-4xl text-primary">
                <%= @form[:num_redis_instances].value %>
              </div>
            </.flex>
            <.flex>
              <PC.input
                min="1"
                max={3}
                step="1"
                field={@form[:num_redis_instances]}
                type="range"
                class="w-full"
              />
            </.flex>
          </.grid>
          <.grid
            :if={@form[:num_redis_instances].value |> Integer.to_integer() > 1}
            columns={[sm: 1, lg: 2]}
            class="items-center"
          >
            <.flex>
              <.h5>Number of Sentinel</.h5>
              <div class="font-bold text-4xl text-primary">
                <%= @form[:num_sentinel_instances].value %>
              </div>
            </.flex>
            <.flex>
              <PC.input
                min="1"
                max={3}
                step="1"
                field={@form[:num_sentinel_instances]}
                type="range"
                class="w-full"
              />
            </.flex>
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
