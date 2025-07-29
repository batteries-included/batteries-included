defmodule HomeBaseWeb.InstallationShowLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias CommonCore.ET.NamespaceReport
  alias HomeBase.CustomerInstalls
  alias HomeBase.ET
  alias HomeBaseWeb.InstallationNewLive
  alias HomeBaseWeb.UserAuth

  on_mount {HomeBaseWeb.RequestURL, :default}

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    owner = UserAuth.current_team_or_user(socket)
    installation = CustomerInstalls.get_installation!(id, owner)
    provider = provider_label(installation.kube_provider)

    {:ok,
     socket
     |> assign(:page, :installations)
     |> assign(:page_title, installation.slug)
     |> assign(:installation, installation)
     |> assign(:provider, provider)
     |> assign(:installed?, !CommonCore.JWK.has_private_key?(installation.control_jwk))
     |> assign_host_report(installation)
     |> assign_usage_report(installation)
     |> assign_ssl_enabled()}
  end

  @impl Phoenix.LiveView
  def handle_params(_unsigned_params, _uri, socket) do
    {:noreply, socket}
  end

  def assign_host_report(socket, install) do
    report =
      case ET.get_most_recent_host_report(install) do
        nil ->
          nil

        report ->
          report.report
      end

    assign(socket, :host_report, report)
  end

  def assign_usage_report(socket, install) do
    report =
      case install |> ET.list_recent_usage_reports(limit: 1) |> List.first() do
        nil ->
          nil

        report ->
          report.report
      end

    assign(socket, :usage_report, report)
  end

  def assign_ssl_enabled(%{assigns: %{installation: %{kube_provider: :kind}}} = socket),
    do: assign(socket, :ssl_enabled?, false)

  def assign_ssl_enabled(%{assigns: %{usage_report: nil}} = socket), do: assign(socket, :ssl_enabled?, false)

  def assign_ssl_enabled(%{assigns: %{usage_report: %{batteries: batteries}}} = socket) do
    assign(socket, :ssl_enabled?, Enum.any?(batteries, fn bat -> bat == "cert_manager" end))
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    case CustomerInstalls.delete_installation(socket.assigns.installation) do
      {:ok, _} ->
        {:noreply, push_navigate(socket, to: ~p"/installations")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def provider_label(provider) do
    CommonCore.Installs.Options.providers()
    |> Enum.find(&(elem(&1, 1) == provider))
    |> elem(0)
    |> Atom.to_string()
  end

  defp control_server_url(%{host_report: nil}), do: ""

  defp control_server_url(%{host_report: %{control_server_host: host}, ssl_enabled?: false}), do: "http://#{host}"

  defp control_server_url(%{host_report: %{control_server_host: host}, ssl_enabled?: true}), do: "https://#{host}"

  defp link_panel(assigns) do
    ~H"""
    <.panel variant="gray" class="lg:order-last">
      <.tab_bar variant="navigation">
        <:tab selected={@live_action == :show} patch={~p"/installations/#{@installation.id}"}>
          Overview
        </:tab>
        <:tab selected={@live_action == :usage} patch={~p"/installations/#{@installation.id}/usage"}>
          Usage
        </:tab>
      </.tab_bar>
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(%{live_action: :success} = assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-full">
      <h2 class="text-4xl font-bold mb-12">Installation Created 🎉</h2>

      <.panel class="mb-8">
        <p class="leading-6 mb-4">
          To download and install the Batteries Included control server in {@provider}, run the script below.
        </p>
        <.script
          src={"#{@request_url}/api/v1/installations/#{@installation.id}/script"}
          class="mt-4 mb-8"
        />
        <.markdown content={explanation(@installation)} />
      </.panel>

      <.button variant="primary" link={~p"/"} icon={:arrow_right} icon_position={:right}>
        Continue to Dashboard
      </.button>
    </div>
    """
  end

  def render(assigns) do
    assigns = assign(assigns, control_server_url: control_server_url(assigns))

    ~H"""
    <%= case @live_action do %>
      <% :usage -> %>
        <.usage_page {assigns} />
      <% _ -> %>
        <.overview_page {assigns} />
    <% end %>
    """
  end

  defp overview_page(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-4">
      <.h2>{@installation.slug}</.h2>
      <div class="flex items-center gap-2">
        <.button variant="icon" icon={:pencil} link={~p"/installations/#{@installation}/edit"} />
        <.button
          variant="icon"
          icon={:trash}
          phx-click="delete"
          data-confirm={"Are you sure you want to delete the #{@installation.slug} installation?"}
        />
      </div>
    </div>

    <.flex column>
      <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
        <.panel :if={!@installed?} title="Installation" class="lg:col-span-4">
          <p class="leading-6 mb-4">
            We haven't heard from your installation yet! To download and install the Batteries Included control server in {@provider}, run the script below.
          </p>
          <.script
            src={"#{@request_url}/api/v1/installations/#{@installation.id}/script"}
            class="mb-8"
          />
          <.markdown content={explanation(@installation)} />
        </.panel>
        <.panel title="Details" class="lg:col-span-3">
          <.data_list>
            <:item title="Usage">{@installation.usage}</:item>
            <:item title="Provider">{@installation.kube_provider}</:item>
            <:item title="Default Size">{@installation.default_size}</:item>
            <:item title="Created">{@installation.inserted_at}</:item>
            <:item :if={@usage_report} title="Nodes">{node_count(@usage_report)}</:item>
            <:item :if={@usage_report} title="Pods">
              {NamespaceReport.pod_count(@usage_report.namespace_report)}
            </:item>
            <:item :if={@usage_report} title="Batteries">{battery_count(@usage_report)}</:item>
          </.data_list>
        </.panel>
        <.link_panel
          live_action={@live_action}
          installation={@installation}
          usage_report={@usage_report}
        />
      </.grid>

      <div class="text-center m-auto flex-1 flex flex-col justify-center p-12">
        <h3 class="text-2xl font-semibold mb-6">Want to expand even more?</h3>
        <.button variant="secondary" icon={:plus} link={~p"/installations/new"} class="self-center">
          Add another installation
        </.button>
      </div>
    </.flex>
    """
  end

  defp usage_page(assigns) do
    ~H"""
    <div class="flex items-center justify-between mb-4">
      <.h2>{@installation.slug}</.h2>
      <div class="flex items-center gap-2">
        <.button variant="icon" icon={:pencil} link={~p"/installations/#{@installation}/edit"} />
        <.button
          variant="icon"
          icon={:trash}
          phx-click="delete"
          data-confirm={"Are you sure you want to delete the #{@installation.slug} installation?"}
        />
      </div>
    </div>

    <.flex column>
      <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
        <.link_panel
          live_action={@live_action}
          installation={@installation}
          usage_report={@usage_report}
        />
        <.panel title="Usage Details" class="lg:col-span-3 lg:row-span-2">
          <div :if={@usage_report}>
            <.data_list>
              <:item title="Nodes">{node_count(@usage_report)}</:item>
              <:item title="Pods">
                {NamespaceReport.pod_count(@usage_report.namespace_report)}
              </:item>
              <:item title="Batteries">{battery_count(@usage_report)}</:item>
            </.data_list>

            <div class="mt-6">
              <h4 class="text-lg font-semibold mb-4">Installed Batteries</h4>
              <.flex class="flex-wrap gap-2">
                <span
                  :for={battery <- @usage_report.batteries}
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400"
                >
                  {battery}
                </span>
              </.flex>
            </div>

            <div :if={@usage_report.node_report} class="mt-6">
              <h4 class="text-lg font-semibold mb-4">Node Information</h4>
              <.data_list>
                <:item :for={{node, pod_count} <- @usage_report.node_report.pod_counts} title={node}>
                  {pod_count} pods
                </:item>
              </.data_list>
            </div>
          </div>
          <div :if={!@usage_report} class="text-center text-lg">
            No usage data available yet
          </div>
        </.panel>
      </.grid>
    </.flex>
    """
  end

  defp node_count(usage_report), do: usage_report.node_report.pod_counts |> Map.keys() |> Enum.count()

  defp battery_count(usage_report), do: Enum.count(usage_report.batteries)

  defp explanation(installation) do
    """
    ## What will this do?

    #{InstallationNewLive.explanation_more(installation.usage)}
    #{InstallationNewLive.explanation_more(installation.kube_provider)}
    """
  end
end
