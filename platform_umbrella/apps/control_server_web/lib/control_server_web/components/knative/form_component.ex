defmodule ControlServerWeb.Live.Knative.FormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.Containers.ContainersPanel
  import ControlServerWeb.Containers.EnvValuePanel
  import ControlServerWeb.Containers.HiddenForms
  import ControlServerWeb.KnativeFormSubcomponents

  alias CommonCore.Containers.Container
  alias CommonCore.Containers.EnvValue
  alias CommonCore.Knative.Service
  alias ControlServer.Knative
  alias Ecto.Changeset
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "service:save" end)
     |> assign_new(:save_target, fn -> nil end)
     |> assign_new(:namespace, fn -> SummaryBatteries.knative_namespace() end)
     |> assign_keycloak_enabled()
     |> assign_projects()
     |> assign_container(nil)
     |> assign_container_idx(nil)
     |> assign_container_field_name(nil)
     |> assign_env_value(nil)
     |> assign_env_value_idx(nil)}
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

  def update_env_value(env_value, idx) do
    send_update(__MODULE__, id: "service-form", env_value: env_value, idx: idx)
  end

  def assign_changeset(socket, changeset) do
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

  defp assign_projects(socket) do
    assign(socket, projects: ControlServer.Projects.list_projects())
  end

  defp assign_keycloak_enabled(socket) do
    assign_new(socket, :keycloak_enabled, fn -> SummaryBatteries.battery_installed(:keycloak) end)
  end

  def assign_container_field_name(socket, cfn) do
    assign(socket, container_field_name: cfn)
  end

  def assign_container(socket, container) do
    assign(socket, container: container)
  end

  def assign_container_idx(socket, idx) do
    assign(socket, container_idx: idx)
  end

  def assign_env_value(socket, env_value) do
    assign(socket, env_value: env_value)
  end

  def assign_env_value_idx(socket, idx) do
    assign(socket, env_value_idx: idx)
  end

  @impl Phoenix.LiveComponent
  def update(%{service: service} = assigns, socket) do
    project_id = Map.get(service, :project_id) || assigns[:project_id]
    changeset = Knative.change_service(service, %{project_id: project_id})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_changeset(changeset)}
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
    {:ok, socket |> assign_env_value(nil) |> assign_env_value_idx(nil)}
  end

  def update(%{env_value: env_value, idx: nil}, %{assigns: %{changeset: changeset}} = socket) do
    env_values = Changeset.get_field(changeset, :env_values, [])
    changeset = Changeset.put_embed(changeset, :env_values, [env_value | env_values])

    {:ok,
     socket
     |> assign_env_value(nil)
     |> assign_env_value_idx(nil)
     |> assign_changeset(changeset)}
  end

  def update(%{env_value: env_value, idx: idx}, %{assigns: %{changeset: changeset}} = socket) do
    env_values = Changeset.get_field(changeset, :env_values, [])
    new_env_values = List.replace_at(env_values, idx, env_value)
    changeset = Changeset.put_embed(changeset, :env_values, new_env_values)

    {:ok,
     socket
     |> assign_env_value(nil)
     |> assign_env_value_idx(nil)
     |> assign_changeset(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"service" => params}, socket) do
    {changeset, _new_service} = Service.validate(params)

    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event("new_env_value", _, socket) do
    new_env_var = %EnvValue{source_type: :value}
    {:noreply, socket |> assign_env_value(new_env_var) |> assign_env_value_idx(nil)}
  end

  def handle_event("edit:env_value", %{"idx" => idx_string}, %{assigns: %{changeset: changeset}} = socket) do
    {idx, _} = Integer.parse(idx_string)

    env_values = Changeset.get_field(changeset, :env_values, [])
    env_value = Enum.fetch!(env_values, idx)

    {:noreply, socket |> assign_env_value(env_value) |> assign_env_value_idx(idx)}
  end

  def handle_event("del:env_value", %{"idx" => env_value_idx}, %{assigns: %{changeset: changeset}} = socket) do
    {idx, ""} = Integer.parse(env_value_idx)

    env_values = changeset |> Changeset.get_field(:env_values, []) |> List.delete_at(idx)
    new_changeset = Changeset.put_embed(changeset, :env_values, env_values)

    {:noreply, assign_changeset(socket, new_changeset)}
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

  defp save_service(socket, :new, service_params) do
    case Knative.create_service(service_params) do
      {:ok, new_service} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Knative service created successfully")
         |> push_navigate(to: ~p"/knative/services/#{new_service.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp save_service(socket, :edit, service_params) do
    service_params =
      service_params
      |> Map.put_new("containers", %{})
      |> Map.put_new("init_containers", %{})
      |> Map.put_new("env_values", %{})

    case Knative.update_service(socket.assigns.service, service_params) do
      {:ok, updated_service} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Knative service updated successfully")
         |> push_navigate(to: ~p"/knative/services/#{updated_service.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp advanced_setting_panel(assigns) do
    ~H"""
    <.panel title="Advanced Settings" variant="gray">
      <.fieldset>
        <.field>
          <:label>Roll Out Duration</:label>
          <.input field={@form[:rollout_duration]} />
        </.field>

        <.field>
          <:label>Project</:label>
          <.input
            type="select"
            field={@form[:project_id]}
            placeholder="No Project"
            placeholder_selectable={true}
            options={Enum.map(@projects, &{&1.name, &1.id})}
          />
        </.field>
      </.fieldset>
    </.panel>
    """
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form
        novalidate
        for={@form}
        id="service-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header
          title={@title}
          back_link={
            if @action == :new,
              do: ~p"/knative/services",
              else: ~p"/knative/services/#{@service}/show"
          }
        >
          <.button variant="dark" type="submit" phx-disable-with="Saving…">
            Save Knative Service
          </.button>
        </.page_header>

        <.grid variant="col-2">
          <.panel>
            <.main_panel form={@form} />
          </.panel>

          <.advanced_setting_panel
            form={@form}
            keycloak_enabled={@keycloak_enabled}
            projects={@projects}
          />

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

          <.env_var_panel env_values={@env_values} editable target={@myself} class="lg:col-span-2" />
          <!-- Hidden inputs for embeds -->
          <.containers_hidden_form field={@form[:containers]} />
          <.containers_hidden_form field={@form[:init_containers]} />
          <.env_values_hidden_form field={@form[:env_values]} />
        </.grid>
      </.form>

      <.live_component
        :if={@container}
        module={ControlServerWeb.Containers.ContainerModal}
        update_func={&update_container/3}
        container={@container}
        idx={@container_idx}
        container_field_name={@container_field_name}
        id="container-form-modal"
      />

      <.live_component
        :if={@env_value}
        module={ControlServerWeb.Containers.EnvValueModal}
        namespace={@namespace}
        update_func={&update_env_value/2}
        env_value={@env_value}
        idx={@env_value_idx}
        id="env_value-form-modal"
      />
    </div>
    """
  end
end
