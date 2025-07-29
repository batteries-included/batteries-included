defmodule ControlServerWeb.Live.UmbrellaSnapshotShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.KeycloakActionsTable
  import ControlServerWeb.ResourcePathsTable
  import ControlServerWeb.SnapshotApply.ShowComponents

  alias ControlServer.SnapshotApply.Keycloak
  alias ControlServer.SnapshotApply.Kube
  alias ControlServer.SnapshotApply.Umbrella

  @impl Phoenix.LiveView
  def mount(%{"id" => id} = _params, _session, socket) do
    {:ok, assign_snapshot(socket, id)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, assign_data_for_action(socket, live_action)}
  end

  defp assign_snapshot(socket, id) do
    assign(socket, :snapshot, Umbrella.get_loaded_snapshot!(id))
  end

  defp assign_data_for_action(socket, :kube) do
    case socket.assigns.snapshot.kube_snapshot do
      nil ->
        socket

      kube_snapshot ->
        kube_data = Kube.get_preloaded_kube_snapshot!(kube_snapshot.id)
        assign(socket, :kube_snapshot, kube_data)
    end
  end

  defp assign_data_for_action(socket, :keycloak) do
    case socket.assigns.snapshot.keycloak_snapshot do
      nil ->
        socket

      keycloak_snapshot ->
        keycloak_data = Keycloak.get_preloaded_keycloak_snapshot!(keycloak_snapshot.id)
        assign(socket, :keycloak_snapshot, keycloak_data)
    end
  end

  defp assign_data_for_action(socket, _), do: socket

  # Overview page template

  # Page Components

  defp overview_page(assigns) do
    ~H"""
    <.page_header title="Show Deploy" back_link={~p"/deploy"}>
      <.snapshot_facts_section snapshot={@snapshot} />
    </.page_header>

    <.flex column>
      <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
        <.link_panel live_action={@live_action} snapshot={@snapshot} />
        <.panel title="Deploy Status" class="lg:col-span-3 lg:row-span-2">
          <.deployment_status_grid snapshot={@snapshot} />
        </.panel>
      </.grid>
    </.flex>
    """
  end

  defp deployment_status_grid(assigns) do
    ~H"""
    <.flex column class="gap-4">
      <.deployment_status_card
        :if={@snapshot.kube_snapshot}
        title="Kubernetes Deployment"
        status={@snapshot.kube_snapshot.status}
      />
      <.deployment_status_card
        :if={!@snapshot.kube_snapshot}
        title="Kubernetes Deployment"
        status="Not Started"
      />

      <.deployment_status_card
        :if={@snapshot.keycloak_snapshot}
        title="Keycloak Deployment"
        status={@snapshot.keycloak_snapshot.status}
      />
      <.deployment_status_card
        :if={!@snapshot.keycloak_snapshot}
        title="Keycloak Deployment"
        status="Not Started"
      />
    </.flex>
    """
  end

  defp deployment_status_card(assigns) do
    ~H"""
    <.flex class="items-center justify-between">
      <h3 class="text-lg font-medium">{@title}</h3>
      <.status_badge status={@status} />
    </.flex>
    """
  end

  defp status_badge(%{status: :ok} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400">
      <.icon name={:check_circle} class="size-3" /> ok
    </span>
    """
  end

  defp status_badge(%{status: :error} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400">
      <.icon name={:exclamation_circle} class="size-3" /> Failed
    </span>
    """
  end

  defp status_badge(%{status: :applying} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400">
      <.icon name={:clock} class="size-3" /> Applying
    </span>
    """
  end

  defp status_badge(%{status: :creation} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400">
      <.icon name={:minus_circle} class="size-3" /> Creation
    </span>
    """
  end

  defp status_badge(assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400">
      <.icon name={:question_mark_circle} class="size-3" />
      {@status}
    </span>
    """
  end

  defp kube_page(assigns) do
    ~H"""
    <.page_header title="Kubernetes Deploy" back_link={~p"/deploy/#{@snapshot.id}/show"}>
      <.snapshot_facts_section snapshot={@snapshot} />
    </.page_header>

    <.flex column>
      <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
        <.link_panel live_action={@live_action} snapshot={@snapshot} />
        <.panel title="Path Results" class="lg:col-span-3 lg:row-span-2">
          <.resource_paths_table :if={@kube_snapshot} rows={@kube_snapshot.resource_paths} />
          <div :if={!@kube_snapshot} class="text-center text-lg">
            Kubernetes deployment not available
          </div>
        </.panel>
      </.grid>
    </.flex>
    """
  end

  defp keycloak_page(assigns) do
    ~H"""
    <.page_header title="Keycloak Deploy" back_link={~p"/deploy/#{@snapshot.id}/show"}>
      <.snapshot_facts_section snapshot={@snapshot} />
    </.page_header>

    <.flex column>
      <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
        <.link_panel live_action={@live_action} snapshot={@snapshot} />
        <.panel title="Action Results" class="lg:col-span-3 lg:row-span-2">
          <.keycloak_action_table
            :if={@keycloak_snapshot && @keycloak_snapshot.keycloak_actions != []}
            rows={@keycloak_snapshot.keycloak_actions}
          />
          <.no_actions :if={@keycloak_snapshot && @keycloak_snapshot.keycloak_actions == []} />
          <div :if={!@keycloak_snapshot} class="text-center text-lg">
            Keycloak deployment not available
          </div>
        </.panel>
      </.grid>
    </.flex>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :overview -> %>
        <.overview_page {assigns} />
      <% :kube -> %>
        <.kube_page {assigns} />
      <% :keycloak -> %>
        <.keycloak_page {assigns} />
      <% _ -> %>
        <.overview_page {assigns} />
    <% end %>
    """
  end
end
