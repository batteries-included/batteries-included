defmodule ControlServerWeb.Live.Home do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Defaults.Namespaces
  alias ControlServer.Batteries
  alias ControlServer.SnapshotApply.Umbrella
  alias ControlServerWeb.RecentProjectsPanel
  alias ControlServerWeb.RunningBatteriesPanel
  alias KubeServices.KubeState

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_catalog_group()
     |> assign_current_page()
     |> assign_page_title()
     |> assign_latest_snapshot()
     |> assign_pods()}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {batteries, meta}} <- Batteries.list_system_batteries(params) do
      {:noreply,
       socket
       |> assign(:batteries, batteries)
       |> assign(:batteries_meta, meta)
       |> assign(:batteries_count, meta.total_count)}
    end
  end

  defp assign_catalog_group(socket) do
    assign(socket, catalog_group: Catalog.group(:home))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: socket.assigns.catalog_group.type)
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: socket.assigns.catalog_group.name)
  end

  defp assign_latest_snapshot(socket) do
    snapshots = Umbrella.latest_umbrella_snapshots(1)

    assign(socket, :latest_snapshot, Enum.at(snapshots, 0))
  end

  def assign_pods(socket) do
    pods = KubeState.get_all(:pod)

    socket
    |> assign(:pods, pods)
    |> assign(:pod_count, Enum.count(pods))
  end

  defp pod_data(pods) do
    count_map =
      pods
      |> Enum.map(&K8s.Resource.FieldAccessors.namespace/1)
      |> Enum.filter(fn ns -> ns != nil and String.contains?(ns, "battery") end)
      |> Enum.reduce(%{}, fn ns, acc ->
        Map.update(acc, Namespaces.humanize(ns), 1, fn v -> v + 1 end)
      end)

    %{
      labels: Map.keys(count_map),
      datasets: [
        %{
          label: "Pods",
          data: Map.values(count_map)
        }
      ]
    }
  end

  defp snapshot_icon(status) do
    case status do
      :ok -> :check_circle
      :error -> :x_circle
      _ -> :arrow_path
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title}>
      <.button variant="dark" icon={:plus} link={~p"/projects/new?return_to=#{~p"/"}"}>
        New Project
      </.button>
    </.page_header>

    <div class="flex flex-wrap items-center justify-between gap-4 mb-4 lg:mb-6">
      <div class="flex flex-wrap gap-4">
        <.badge label="Batteries Running" value={@batteries_count} />
        <.badge label="Pods" value={@pod_count} />
      </div>

      <.button
        :if={@latest_snapshot && @latest_snapshot.kube_snapshot}
        variant="minimal"
        link={~p"/deploy"}
        icon={snapshot_icon(@latest_snapshot.kube_snapshot.status)}
      >
        Last Deploy: {Calendar.strftime(@latest_snapshot.inserted_at, "%b %-d, %-I:%M%p")}
      </.button>
    </div>

    <.grid columns={%{md: 1, lg: 12}}>
      <.flex column class="lg:col-span-6 xl:col-span-5">
        <.h3>Pods by Category</.h3>
        <.chart id="pod-chart" data={pod_data(@pods)} />
      </.flex>

      <.live_component
        module={RecentProjectsPanel}
        id="recent_projects"
        class="lg:col-start-8 lg:col-span-5"
      />

      <.live_component
        module={RunningBatteriesPanel}
        id="running_bat_home_hero"
        class="lg:col-span-12"
        batteries={@batteries}
        meta={@batteries_meta}
      />
    </.grid>
    """
  end
end
