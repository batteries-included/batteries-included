defmodule ControlServerWeb.BatteriesFormComponent do
  @moduledoc false

  use ControlServerWeb, :live_component

  import Ecto.Changeset

  alias CommonCore.Batteries.SystemBattery
  alias ControlServer.Batteries
  alias ControlServer.Batteries.Installer
  alias ControlServerWeb.Batteries.AWSLoadBalancerControllerForm
  alias ControlServerWeb.Batteries.BatteryCAForm
  alias ControlServerWeb.Batteries.BatteryCoreForm
  alias ControlServerWeb.Batteries.CertManagerForm
  alias ControlServerWeb.Batteries.CloudnativePGBarmanForm
  alias ControlServerWeb.Batteries.CloudnativePGForm
  alias ControlServerWeb.Batteries.FerretDBForm
  alias ControlServerWeb.Batteries.ForgejoForm
  alias ControlServerWeb.Batteries.GatewayAPIForm
  alias ControlServerWeb.Batteries.GrafanaForm
  alias ControlServerWeb.Batteries.IstioCSRForm
  alias ControlServerWeb.Batteries.IstioForm
  alias ControlServerWeb.Batteries.IstioGatewayForm
  alias ControlServerWeb.Batteries.KarpenterForm
  alias ControlServerWeb.Batteries.KeycloakForm
  alias ControlServerWeb.Batteries.KialiForm
  alias ControlServerWeb.Batteries.KnativeForm
  alias ControlServerWeb.Batteries.KubeMonitoringForm
  alias ControlServerWeb.Batteries.LokiForm
  alias ControlServerWeb.Batteries.MetalLBForm
  alias ControlServerWeb.Batteries.NodeFeatureDiscoveryForm
  alias ControlServerWeb.Batteries.NotebooksForm
  alias ControlServerWeb.Batteries.NvidiaDevicePluginForm
  alias ControlServerWeb.Batteries.OllamaForm
  alias ControlServerWeb.Batteries.ProjectExportForm
  alias ControlServerWeb.Batteries.PromtailForm
  alias ControlServerWeb.Batteries.RedisForm
  alias ControlServerWeb.Batteries.SSOForm
  alias ControlServerWeb.Batteries.StaleResourceCleanerForm
  alias ControlServerWeb.Batteries.TimelineForm
  alias ControlServerWeb.Batteries.TraditionalServicesForm
  alias ControlServerWeb.Batteries.TrivyOperatorForm
  alias ControlServerWeb.Batteries.TrustManagerForm
  alias ControlServerWeb.Batteries.VictoriaMetricsForm
  alias ControlServerWeb.Batteries.VMAgentForm

  # styler:sort
  @possible_forms [
    aws_load_balancer_controller: AWSLoadBalancerControllerForm,
    battery_ca: BatteryCAForm,
    battery_core: BatteryCoreForm,
    cert_manager: CertManagerForm,
    cloudnative_pg: CloudnativePGForm,
    cloudnative_pg_barman: CloudnativePGBarmanForm,
    ferretdb: FerretDBForm,
    forgejo: ForgejoForm,
    gateway_api: GatewayAPIForm,
    grafana: GrafanaForm,
    istio: IstioForm,
    istio_csr: IstioCSRForm,
    istio_gateway: IstioGatewayForm,
    karpenter: KarpenterForm,
    keycloak: KeycloakForm,
    kiali: KialiForm,
    knative: KnativeForm,
    kube_monitoring: KubeMonitoringForm,
    loki: LokiForm,
    metallb: MetalLBForm,
    node_feature_discovery: NodeFeatureDiscoveryForm,
    notebooks: NotebooksForm,
    nvidia_device_plugin: NvidiaDevicePluginForm,
    ollama: OllamaForm,
    project_export: ProjectExportForm,
    promtail: PromtailForm,
    redis: RedisForm,
    sso: SSOForm,
    stale_resource_cleaner: StaleResourceCleanerForm,
    timeline: TimelineForm,
    traditional_services: TraditionalServicesForm,
    trivy_operator: TrivyOperatorForm,
    trust_manager: TrustManagerForm,
    victoria_metrics: VictoriaMetricsForm,
    vm_agent: VMAgentForm
  ]

  def update(assigns, socket) do
    config_module = SystemBattery.for_type(assigns.catalog_battery.type)
    form_module = Keyword.fetch!(@possible_forms, assigns.catalog_battery.type)

    config = if assigns[:system_battery], do: assigns.system_battery.config, else: struct(config_module)
    changeset = config_module.changeset(config, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:config_module, config_module)
     |> assign(:form_module, form_module)
     |> assign(:form, to_form(changeset))
     |> assign_new(:system_battery, fn -> %SystemBattery{config: config} end)}
  end

  def handle_event("validate", %{"battery_config" => params}, socket) do
    changeset =
      socket.assigns.system_battery.config
      |> socket.assigns.config_module.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("new:save", %{"battery_config" => params}, socket) do
    target = self()

    case socket.assigns.system_battery.config
         |> socket.assigns.config_module.changeset(params)
         |> apply_action(:insert) do
      {:ok, config} ->
        send(target, {:async_installer, :start})

        _ =
          Task.async(fn ->
            # Yes these are sleeps to make this slower.
            #
            # There's a lot going on here an showing the user
            # that is somewhat important. Giving some time inbetween
            # these steps show that there's stuff happening to them.
            Process.sleep(800)
            Installer.install!(socket.assigns.catalog_battery.type, config: config, update_target: target)
            Process.sleep(800)
            send(target, {:async_installer, :starting_kube})
            KubeServices.SnapshotApply.Worker.start()
            Process.sleep(800)
            send(target, {:async_installer, {:apply_complete, "Started"}})
          end)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # Handles form submissions that don't have any inputs.
  def handle_event("new:save", _params, socket) do
    handle_event("new:save", %{"battery_config" => %{}}, socket)
  end

  def handle_event("edit:save", %{"battery_config" => params}, socket) do
    case socket.assigns.system_battery.config
         |> socket.assigns.config_module.changeset(params)
         |> apply_action(:update) do
      {:ok, config} ->
        system_battery = Map.put(socket.assigns.system_battery, :config, config)
        Batteries.update_system_battery(socket.assigns.system_battery, system_battery)

        {:noreply,
         socket
         |> put_flash(:global_success, "Battery has been updated")
         |> push_navigate(to: ~p"/batteries/#{socket.assigns.catalog_battery.group}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # Handles form submissions that don't have any inputs.
  def handle_event("edit:save", _params, socket) do
    handle_event("edit:save", %{"battery_config" => %{}}, socket)
  end

  def handle_event("uninstall", _params, socket) do
    case Batteries.delete_system_battery(socket.assigns.system_battery) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Battery has been uninstalled")
         |> push_navigate(to: ~p"/batteries/#{socket.assigns.catalog_battery.group}")}

      _ ->
        {:noreply, put_flash(socket, :global_error, "Could not uninstall battery")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form
        :let={f}
        id={@id}
        for={@form}
        as={:battery_config}
        phx-change="validate"
        phx-submit={submit_event(@action)}
        phx-target={@myself}
        novalidate
      >
        <.page_header
          title={"#{@catalog_battery.name} Battery"}
          back_link={~p"/batteries/#{@catalog_battery.group}"}
        >
          <:menu :if={@action == :edit}>
            <.badge
              minimal
              label="ACTIVE"
              class="bg-green-500 dark:bg-green-500 text-white dark:text-white"
            />
          </:menu>

          <div class="flex items-center gap-8">
            <.button
              :if={@action == :edit && @catalog_battery.uninstallable}
              variant="minimal"
              icon={:power}
              phx-click="uninstall"
              phx-target={@myself}
              data-confirm={"Are you sure you want to uninstall the #{@catalog_battery.name} battery?"}
            >
              Uninstall
            </.button>

            <.button variant="dark" type="submit">
              {if @action == :new, do: "Install", else: "Save"} Battery
            </.button>
          </div>
        </.page_header>

        <.grid variant="col-2">
          <.live_component
            module={@form_module}
            battery={@catalog_battery}
            form={f}
            action={@action}
            id="battery-subform"
          />
        </.grid>
      </.form>
    </div>
    """
  end

  defp submit_event(:new), do: "new:save"
  defp submit_event(:edit), do: "edit:save"
end
