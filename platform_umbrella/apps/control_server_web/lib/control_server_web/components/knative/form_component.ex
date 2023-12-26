defmodule ControlServerWeb.Live.Knative.FormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  import CommonUI.Table
  import CommonUI.Tooltip
  import ControlServerWeb.Knative.EnvValuePanel
  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Knative.Container
  alias CommonCore.Knative.EnvValue
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
     |> assign_new(:sso_enabled, fn -> SummaryBatteries.battery_installed(:sso) end)
     |> assign_container(nil)
     |> assign_env_value(nil)}
  end

  def update_container(container) do
    send_update(__MODULE__, id: "service-form", container: container)
  end

  def update_env_value(env_value) do
    send_update(__MODULE__, id: "service-form", env_value: env_value)
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

  def assign_url(socket, service) do
    assign(socket, url: "http://#{knative_host(service)}")
  end

  def assign_container(socket, container) do
    assign(socket, container: container)
  end

  def assign_env_value(socket, env_value) do
    assign(socket, env_value: env_value)
  end

  @impl Phoenix.LiveComponent
  def update(%{service: service} = assigns, socket) do
    changeset = Knative.change_service(service)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_url(service)
     |> assign_changeset(changeset)}
  end

  def update(%{container: nil}, socket) do
    {:ok, assign_container(socket, nil)}
  end

  def update(%{container: container}, %{assigns: %{changeset: changeset}} = socket) do
    containers = Changeset.get_field(changeset, :containers, [])
    changeset = Changeset.put_embed(changeset, :containers, [container | containers])
    {:ok, socket |> assign_container(nil) |> assign_changeset(changeset)}
  end

  def update(%{env_value: nil}, socket) do
    {:ok, assign_env_value(socket, nil)}
  end

  def update(%{env_value: env_value}, %{assigns: %{changeset: changeset}} = socket) do
    env_values = Changeset.get_field(changeset, :env_values, [])
    changeset = Changeset.put_embed(changeset, :env_values, [env_value | env_values])
    {:ok, socket |> assign_env_value(nil) |> assign_changeset(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"service" => params}, socket) do
    {changeset, new_service} = Service.validate(params)

    {:noreply,
     socket
     |> assign_changeset(changeset)
     |> assign_url(new_service)}
  end

  def handle_event("new_container", _, socket) do
    {:noreply, assign_container(socket, %Container{})}
  end

  def handle_event("new_env_var", _, socket) do
    {:noreply, assign_env_value(socket, %EnvValue{source_type: :value})}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, assign_container(socket, nil)}
  end

  def handle_event("del:container", %{"idx" => container_idx}, %{assigns: %{changeset: changeset}} = socket) do
    {idx, _} = Integer.parse(container_idx)

    containers =
      Changeset.get_field(changeset, :containers, [])

    new_containers = List.delete_at(containers, idx)
    new_changeset = Changeset.put_embed(changeset, :containers, new_containers)

    {:noreply, assign_changeset(socket, new_changeset)}
  end

  def handle_event("del:env_value", %{"idx" => env_value_idx}, %{assigns: %{changeset: changeset}} = socket) do
    {idx, ""} = Integer.parse(env_value_idx)

    env_values =
      changeset |> Changeset.get_field(:env_values, []) |> List.delete_at(idx)

    new_changeset = Changeset.put_embed(changeset, :env_values, env_values)

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
         |> put_flash(:info, "Knative service created successfully")
         |> push_redirect(to: ~p"/knative/services/#{new_service.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp save_service(socket, :edit, service_params) do
    case Knative.update_service(socket.assigns.service, service_params) do
      {:ok, updated_service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Knative service updated successfully")
         |> push_redirect(to: ~p"/knative/services/#{updated_service.id}/show")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp containers_panel(assigns) do
    ~H"""
    <.panel title="Containers">
      <:menu>
        <.button
          variant="transparent"
          icon={:plus}
          phx-click="new_container"
          type="button"
          phx-target={@myself}
        >
          Container
        </.button>
      </:menu>
      <.table rows={Enum.with_index(@containers ++ @init_containers)}>
        <:col :let={{c, _idx}} label="Name"><%= c.name %></:col>
        <:col :let={{c, _idx}} label="Image"><%= c.image %></:col>
        <:col :let={{_c, idx}} label="Init Container">
          <%= if idx > length(@containers), do: "Yes", else: "No" %>
        </:col>

        <:action :let={{c, idx}}>
          <.action_icon
            to="/"
            icon={:x_mark}
            id={"delete_container_" <> String.replace(c.name, " ", "")}
            phx-click="del:container"
            phx-value-idx={if idx > length(@containers), do: idx - length(@containers), else: idx}
            tooltip="Remove"
            link_type="button"
            type="button"
            phx-target={@myself}
          />
        </:action>
      </.table>
    </.panel>
    """
  end

  defp env_values_inputs(assigns) do
    ~H"""
    <.inputs_for :let={env_value} field={@field}>
      <.single_env_value_hidden form={env_value} />
    </.inputs_for>
    """
  end

  defp single_env_value_hidden(assigns) do
    ~H"""
    <PC.input type="hidden" field={@form[:name]} />
    <PC.input type="hidden" field={@form[:value]} />
    <PC.input type="hidden" field={@form[:source_type]} />
    <PC.input type="hidden" field={@form[:source_name]} />
    <PC.input type="hidden" field={@form[:source_key]} />
    <PC.input type="hidden" field={@form[:source_optional]} />
    """
  end

  defp containers_hidden_form(assigns) do
    ~H"""
    <.inputs_for :let={f_nested} field={@field}>
      <PC.input type="hidden" field={f_nested[:name]} />
      <PC.input type="hidden" field={f_nested[:image]} />
      <PC.input type="hidden" field={f_nested[:command]} multiple={true} />
      <PC.input type="hidden" field={f_nested[:args]} multiple={true} />
      <.inputs_for :let={env_nested} field={f_nested[:env_values]}>
        <.single_env_value_hidden form={env_nested} />
      </.inputs_for>
    </.inputs_for>
    """
  end

  defp advanced_setting_panel(assigns) do
    ~H"""
    <.panel title="Advanced Settings" variant="gray">
      <.flex class="flex-col">
        <PC.field field={@form[:rollout_duration]} />
        <PC.field
          :if={@sso_enabled}
          field={@form[:oauth2_proxy]}
          type="switch"
          label="Protect with OAuth2 Proxy"
        />
      </.flex>
    </.panel>
    """
  end

  defp name_panel(assigns) do
    ~H"""
    <PC.field field={@form[:name]} autofocus placeholder="Name" />
    """
  end

  defp url_panel(assigns) do
    ~H"""
    <.flex class="justify-around items-center">
      <.truncate_tooltip value={@url} length={72} />
    </.flex>
    """
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="service-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header
          title={@title}
          back_button={%{link_type: "live_redirect", to: ~p"/knative/services"}}
        >
          <:menu>
            <PC.button label="Save Serverless" color="dark" phx-disable-with="Saving…" />
          </:menu>
        </.page_header>
        <.grid columns={[sm: 1, md: 2]}>
          <.name_panel form={@form} />
          <.url_panel url={@url} />
          <.containers_panel
            myself={@myself}
            init_containers={@init_containers}
            containers={@containers}
          />
          <.advanced_setting_panel form={@form} sso_enabled={@sso_enabled} />
          <.env_var_panel env_values={@env_values} editable target={@myself} />
          <!-- Hidden inputs for embeds -->
          <.containers_hidden_form field={@form[:containers]} />
          <.containers_hidden_form field={@form[:init_containers]} />
          <.env_values_inputs field={@form[:env_values]} />
        </.grid>
      </.form>

      <.live_component
        :if={@container}
        module={ControlServerWeb.Knative.ContainerModal}
        container={@container}
        id="container-form-modal"
      />

      <.live_component
        :if={@env_value}
        module={ControlServerWeb.Knative.EnvValueModal}
        env_value={@env_value}
        id="env_value-form-modal"
      />
    </div>
    """
  end
end
