defmodule ControlServerWeb.Live.Home do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Chart

  alias CommonCore.Batteries.Catalog
  alias ControlServer.SnapshotApply.Kube
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
     |> assign_pods()
     |> assign_status(Kube.get_latest_snapshot_status())}
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

  def assign_pods(socket) do
    assign(socket, pods: KubeState.get_all(:pod))
  end

  def assign_status(socket, status) do
    assign(socket, status: status)
  end

  defp pod_data(pods) do
    count_map =
      pods
      |> Enum.map(&K8s.Resource.FieldAccessors.namespace/1)
      |> Enum.filter(fn ns -> ns != nil and String.contains?(ns, "battery") end)
      |> Enum.reduce(%{}, fn ns, acc ->
        Map.update(acc, ns, 1, fn v -> v + 1 end)
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

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title}>
      <div class="flex items-center gap-4">
        <.button variant="dark" icon={:plus} link={~p"/projects/new?return_to=#{~p"/"}"}>
          New Project
        </.button>

        <.button variant="secondary" icon={:kubernetes} link={~p"/batteries/magic"}>
          Manage Batteries
        </.button>
      </div>
    </.page_header>

    <.grid columns={%{sm: 1, lg: 12}} class="w-full">
      <.flex column class="items-center lg:col-span-5">
        <.h3>Pods by Category</.h3>
        <.chart id="pod-chart" type="doughnut" data={pod_data(@pods)} class="max-w-xl" />
      </.flex>

      <.live_component module={RecentProjectsPanel} id="recent_projects" />
      <.live_component module={RunningBatteriesPanel} id="running_bat_home_hero" />
    </.grid>
    """
  end
end
