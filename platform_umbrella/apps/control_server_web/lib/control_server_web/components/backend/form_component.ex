defmodule ControlServerWeb.Live.TraditionalServices.FormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.BackendFormSubcomponents
  import ControlServerWeb.Containers.ContainersPanel
  import ControlServerWeb.Containers.EnvValuePanel
  import ControlServerWeb.Containers.HiddenForms

  alias CommonCore.Containers.Container
  alias CommonCore.Containers.EnvValue
  alias CommonCore.TraditionalServices.Service
  alias ControlServer.TraditionalServices
  alias Ecto.Changeset
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "service:save" end)
     |> assign_new(:save_target, fn -> nil end)
     |> assign_new(:sso_enabled, fn -> SummaryBatteries.battery_installed(:sso) end)
     |> assign_container(nil)
     |> assign_container_idx(nil)
     |> assign_container_field_name(nil)
     |> assign_env_value(nil)
     |> assign_env_value_idx(nil)}
  end

  @impl Phoenix.LiveComponent
  def update(%{service: service, title: title, action: action} = assigns, socket) do
    project_id = Map.get(service, :project_id) || assigns[:project_id]
    changeset = TraditionalServices.change_service(service, %{project_id: project_id})

    {:ok,
     socket
     |> assign_changeset(changeset)
     |> assign_title(title)
     |> assign_service(service)
     |> assign_action(action)
     |> assign_projects()}
  end

  def update(%{container: nil}, socket) do
    {:ok, socket |> assign_container(nil) |> assign_container_idx(nil) |> assign_container_field_name(nil)}
  end

  def update(
        %{container: container, idx: nil, container_field_name: container_field_name},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    containers = Changeset.get_field(changeset, container_field_name, [])
    changeset = Changeset.put_embed(changeset, container_field_name, [container | containers])

    {:ok,
     socket
     |> assign_container(nil)
     |> assign_container_idx(nil)
     |> assign_container_field_name(nil)
     |> assign_changeset(changeset)}
  end

  def update(
        %{container: container, idx: idx, container_field_name: container_field_name},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    containers = Changeset.get_field(changeset, container_field_name, [])
    new_containers = List.replace_at(containers, idx, container)
    changeset = Changeset.put_embed(changeset, container_field_name, new_containers)

    {:ok,
     socket
     |> assign_container(nil)
     |> assign_container_idx(nil)
     |> assign_container_field_name(nil)
     |> assign_changeset(changeset)}
  end

  def update(%{env_value: nil}, socket) do
    {:ok, assign(socket, env_value: nil, env_value_idx: nil)}
  end

  def update(%{env_value: env_value, idx: nil}, %{assigns: %{changeset: changeset}} = socket) do
    env_values = Changeset.get_field(changeset, :env_values, [])
    changeset = Changeset.put_embed(changeset, :env_values, [env_value | env_values])

    {:ok, socket |> assign(env_value: nil, env_value_idx: nil) |> assign_changeset(changeset)}
  end

  def update(%{env_value: env_value, idx: idx}, %{assigns: %{changeset: changeset}} = socket) do
    env_values =
      changeset
      |> Changeset.get_field(:env_values, [])
      |> List.replace_at(idx, env_value)

    changeset = Changeset.put_embed(changeset, :env_values, env_values)

    {:ok, socket |> assign(env_value: nil, env_value_idx: nil) |> assign_changeset(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"service" => params}, %{assigns: %{service: service}} = socket) do
    changeset = Service.changeset(service, params)

    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event("new_env_value", _, socket) do
    new_env_var = %EnvValue{source_type: :value}
    {:noreply, socket |> assign_env_value(new_env_var) |> assign_env_value_idx(nil)}
  end

  def handle_event("new_container", %{"id" => "containers_panel-" <> cfn}, socket) do
    new_container = %Container{}

    {:noreply,
     socket
     |> assign_container(new_container)
     |> assign_container_idx(nil)
     |> assign_container_field_name(String.to_existing_atom(cfn))}
  end

  def handle_event(
        "edit:container",
        %{"idx" => container_idx, "id" => "containers_panel-" <> cfn},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    {idx, _} = Integer.parse(container_idx)
    container_field_name = String.to_existing_atom(cfn)
    containers = Changeset.get_field(changeset, container_field_name, [])
    container = Enum.fetch!(containers, idx)

    {:noreply,
     socket
     |> assign_container(container)
     |> assign_container_idx(idx)
     |> assign_container_field_name(container_field_name)}
  end

  def handle_event(
        "del:container",
        %{"idx" => container_idx, "id" => "containers_panel-" <> cfn},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    {idx, _} = Integer.parse(container_idx)

    container_field_name = String.to_existing_atom(cfn)
    containers = Changeset.get_field(changeset, container_field_name, [])

    new_containers = List.delete_at(containers, idx)
    new_changeset = Changeset.put_embed(changeset, container_field_name, new_containers)

    {:noreply, assign_changeset(socket, new_changeset)}
  end

  def handle_event("save", %{"service" => service_params}, socket) do
    save_service(socket, socket.assigns.action, service_params)
  end

  @spec update_container(Container.t() | nil, integer | nil, atom()) :: :ok
  def update_container(container, idx, container_field_name) do
    send_update(__MODULE__,
      id: "service-form",
      container: container,
      idx: idx,
      container_field_name: container_field_name
    )
  end

  @spec update_env_value(EnvValue.t() | nil, integer | nil) :: :ok
  def update_env_value(env_value, idx) do
    send_update(__MODULE__, id: "service-form", env_value: env_value, idx: idx)
  end

  def assign_container(socket, container) do
    assign(socket, container: container)
  end

  def assign_container_idx(socket, idx) do
    assign(socket, container_idx: idx)
  end

  def assign_container_field_name(socket, cfn) do
    assign(socket, container_field_name: cfn)
  end

  def assign_env_value(socket, env_value) do
    assign(socket, env_value: env_value)
  end

  def assign_env_value_idx(socket, idx) do
    assign(socket, env_value_idx: idx)
  end

  defp assign_changeset(socket, changeset) do
    containers = Changeset.get_field(changeset, :containers, [])
    init_containers = Changeset.get_field(changeset, :init_containers, [])
    env_values = Changeset.get_field(changeset, :env_values, [])

    assign(socket,
      changeset: changeset,
      form: to_form(changeset),
      containers: containers,
      init_containers: init_containers,
      env_values: env_values
    )
  end

  defp assign_title(socket, title) do
    assign(socket, title: title)
  end

  defp assign_service(socket, service) do
    assign(socket, service: service)
  end

  defp assign_action(socket, action) do
    assign(socket, action: action)
  end

  defp assign_projects(socket) do
    assign(socket, projects: ControlServer.Projects.list_projects())
  end

  defp save_service(socket, :new, service_params) do
    case TraditionalServices.create_service(service_params) do
      {:ok, service} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Traditional Service created successfully")
         |> push_navigate(to: ~p"/traditional_services/#{service}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp save_service(socket, :edit, service_params) do
    case TraditionalServices.update_service(socket.assigns.service, service_params) do
      {:ok, service} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Traditional Service updated successfully")
         |> push_navigate(to: ~p"/traditional_services/#{service}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="backend-service-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header
          title={@title}
          back_link={
            if @action == :new,
              do: ~p"/traditional_services",
              else: ~p"/traditional_services/#{@service}/show"
          }
        >
          <.button variant="dark" type="submit" phx-disable-with="Saving…">
            Save Traditional Service
          </.button>
        </.page_header>
        <.flex column>
          <.panel>
            <.main_panel form={@form} />
          </.panel>

          <.grid columns={[sm: 1, lg: 2]}>
            <.containers_panel
              id="containers_panel-init_containers"
              title="Init Containers"
              target={@myself}
              containers={@init_containers}
            />
            <.containers_panel
              id="containers_panel-containers"
              target={@myself}
              containers={@containers}
            />
            <.panel variant="gray" title="Advanced Settings">
              <.flex column>
                <.input
                  field={@form[:project_id]}
                  type="select"
                  label="Project"
                  placeholder="No Project"
                  placeholder_selectable={true}
                  options={Enum.map(@projects, &{&1.name, &1.id})}
                />
                <.input
                  label="Kube Deployment Type"
                  field={@form[:kube_deployment_type]}
                  type="select"
                  options={["Stateful Set": "statefulset", Deployment: "deployment"]}
                />
                <.h5 class="mt-2">Number of Instances</.h5>
                <.input
                  label="Number of Instances"
                  field={@form[:num_instances]}
                  type="range"
                  min="1"
                  max={5}
                  step="1"
                />
              </.flex>
            </.panel>

            <.env_var_panel env_values={@env_values} editable target={@myself} />
            <!-- Hidden inputs for embeds -->
            <.containers_hidden_form field={@form[:containers]} />
            <.containers_hidden_form field={@form[:init_containers]} />
            <.env_values_hidden_form field={@form[:env_values]} />
          </.grid>
        </.flex>
      </.form>

      <.live_component
        :if={@container}
        module={ControlServerWeb.Containers.ContainerModal}
        update_func={&update_container/3}
        container_field_name={@container_field_name}
        container={@container}
        idx={@container_idx}
        id="container-form-modal"
      />

      <.live_component
        :if={@env_value}
        module={ControlServerWeb.Containers.EnvValueModal}
        update_func={&update_env_value/2}
        env_value={@env_value}
        idx={@env_value_idx}
        id="env_value-form-modal"
      />
    </div>
    """
  end
end
