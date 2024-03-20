defmodule ControlServerWeb.FerretDBFormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.FerretDB.FerretService
  alias CommonCore.Util.Memory
  alias ControlServer.FerretDB
  alias ControlServer.Postgres
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="ferret_service-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header title={@title} back_link={~p"/ferretdb"}>
          <.button variant="dark" type="submit" phx-disable-with="Saving…">
            Save FerretDB Service
          </.button>
        </.page_header>
        <.panel>
          <.grid columns={[sm: 1, md: 2]}>
            <PC.field field={@form[:name]} label="Name" disabled={@action == :edit} />
            <PC.field
              field={@form[:postgres_cluster_id]}
              label="Postgres Cluster"
              type="select"
              prompt="Choose a postgres cluster"
              options={Enum.map(@pg_clusters, &{&1.name, &1.id})}
            />
            <PC.field
              field={@form[:virtual_size]}
              type="select"
              label="Size"
              prompt="Choose a size"
              options={FerretService.preset_options_for_select()}
            />

            <.grid columns={[sm: 1, lg: 2]} class="items-center">
              <.flex>
                <.h5>Number of instances</.h5>
                <div class="font-bold text-4xl text-primary">
                  <%= @form[:instances].value %>
                </div>
              </.flex>
              <.flex>
                <PC.input
                  min="1"
                  max={3}
                  step="1"
                  field={@form[:instances]}
                  type="range"
                  class="w-full"
                />
              </.flex>
            </.grid>
          </.grid>
          <.data_horizontal_bolded
            :if={@form[:virtual_size].value != "custom"}
            class="mt-3 mb-5"
            data={[
              {"Memory limits:", @form[:memory_limits].value |> Memory.format_bytes(true)},
              {"CPU limits:", @form[:cpu_limits].value}
            ]}
          />

          <.grid :if={@form[:virtual_size].value == "custom"} columns={[sm: 1, md: 2, xl: 4]}>
            <PC.field field={@form[:cpu_requested]} label="Cpu requested" />
            <PC.field field={@form[:cpu_limits]} label="Cpu limits" />
            <PC.field field={@form[:memory_requested]} label="Memory requested" />
            <PC.field field={@form[:memory_limits]} label="Memory limits" />
          </.grid>
        </.panel>
      </.form>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{ferret_service: ferret_service} = assigns, socket) do
    changeset = FerretDB.change_ferret_service(ferret_service)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset(changeset)
     |> assign_posssible_clusters()}
  end

  defp assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  defp assign_posssible_clusters(socket) do
    clusters = Postgres.normal_clusters()
    assign(socket, pg_clusters: clusters)
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"ferret_service" => ferret_service_params}, socket) do
    changeset =
      socket.assigns.ferret_service
      |> FerretDB.change_ferret_service(maybe_add_sizes(ferret_service_params, socket.assigns.changeset))
      |> Map.put(:action, :validate)

    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event("save", %{"ferret_service" => ferret_service_params}, socket) do
    save_ferret_service(socket, socket.assigns.action, ferret_service_params)
  end

  defp maybe_add_sizes(%{"virtual_size" => "custom"} = params, changeset) do
    old_vert_size = Changeset.get_field(changeset, :virtual_size)

    if old_vert_size != "custom" && old_vert_size != nil do
      old_vert_size
      |> FerretService.preset_by_name()
      |> Enum.reject(fn {k, _} -> k == :name || k == "name" end)
      |> Enum.reduce(params, fn {k, v}, acc -> Map.put(acc, Atom.to_string(k), v) end)
    else
      params
    end
  end

  defp maybe_add_sizes(params, _old_service), do: params

  defp save_ferret_service(socket, :edit, ferret_service_params) do
    case FerretDB.update_ferret_service(socket.assigns.ferret_service, ferret_service_params) do
      {:ok, ferret_service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ferret service updated successfully")
         |> push_redirect(to: ~p"/ferretdb/#{ferret_service.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp save_ferret_service(socket, :new, ferret_service_params) do
    case FerretDB.create_ferret_service(ferret_service_params) do
      {:ok, ferret_service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Ferret service created successfully")
         |> push_redirect(to: ~p"/ferretdb/#{ferret_service.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end
end
