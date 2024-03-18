defmodule ControlServerWeb.Live.Home do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Chart

  alias ControlServer.Projects
  alias ControlServer.SnapshotApply.Kube
  alias ControlServerWeb.RunningBatteriesPanel
  alias KubeServices.KubeState

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(current_page: :home)
     |> assign_page_title()
     |> assign_pods()
     |> assign_projects()
     |> assign_status(Kube.get_latest_snapshot_status())}
  end

  def assign_page_title(socket) do
    assign(socket, page_title: "Home")
  end

  def assign_pods(socket) do
    assign(socket, pods: KubeState.get_all(:pod))
  end

  def assign_projects(socket) do
    assign(socket, projects: Projects.list_projects())
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
      <:menu>
        <div class="flex items-center gap-4">
          <.button variant="dark" icon={:plus} link={~p"/projects/new"}>
            New Project
          </.button>

          <.button variant="secondary" icon={:kubernetes} link={~p"/batteries/magic"}>
            Manage Batteries
          </.button>
        </div>
      </:menu>
    </.page_header>

    <.grid columns={%{sm: 1, lg: 12}} class="w-full">
      <.flex column class="items-center lg:col-span-5">
        <.h3>Pods by Category</.h3>
        <.chart id="pod-chart" type="doughnut" data={pod_data(@pods)} class="max-w-xl" />
      </.flex>

      <.panel title="Projects" class="lg:col-span-7">
        <:menu>
          <.button variant="minimal" link={~p"/projects"}>View All</.button>
        </:menu>

        <.table rows={@projects} row_click={&JS.navigate(~p"/projects/#{&1.id}")}>
          <:col :let={project} label="Project Name"><%= project.name %></:col>
          <:col :let={project} label="Project Type"><%= project.type %></:col>
        </.table>
      </.panel>

      <.live_component module={RunningBatteriesPanel} id="running_bat_home_hero" />
    </.grid>
    """
  end
end
