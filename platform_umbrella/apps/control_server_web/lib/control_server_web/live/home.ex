defmodule ControlServerWeb.Live.Home do
  use ControlServerWeb, {:live_view, layout: :fresh}

  import ControlServerWeb.Chart

  alias KubeServices.KubeState
  alias Phoenix.Naming
  alias ControlServer.SnapshotApply.Kube

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_page_group(:home)
     |> assign_page_title("Home")
     |> assign_pods(KubeState.get_all(:pod))
     |> assign_nodes(KubeState.get_all(:node))
     |> assign_status(Kube.get_latest_snapshot_status())}
  end

  def assign_page_group(socket, page_group) do
    assign(socket, page_group: page_group)
  end

  def assign_page_title(socket, page_title) do
    assign(socket, page_title: page_title)
  end

  def assign_pods(socket, pods) do
    assign(socket, pods: pods)
  end

  def assign_nodes(socket, nodes) do
    assign(socket, nodes: nodes)
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

  defp most_recent(batteries, n \\ 8) do
    batteries
    |> Enum.sort_by(& &1.inserted_at, :desc)
    |> Enum.slice(-n..-1)
  end

  defp status_icon(%{status: :ok} = assigns),
    do: ~H"""
    <Heroicons.check_circle class="w-auto h-16 text-shamrock-500" />
    """

  defp status_icon(%{status: _} = assigns),
    do: ~H"""
    <Heroicons.exclamation_circle class="w-auto h-16 text-heath-100" />
    """

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="grid md:grid-cols-2 xl:grid-cols-4 gap-6">
      <.card>
        <:title>Battery Count</:title>
        <div class="text-6xl text-center text-secondary">
          <%= length(@installed_batteries) %>
        </div>
      </.card>
      <.card>
        <:title>Last Deploy</:title>
        <.status_icon status={@status} />
      </.card>

      <.card>
        <:title>Total Pods</:title>
        <div class="text-6xl text-center text-pink-500"><%= length(@pods) %></div>
      </.card>
      <.card>
        <:title>Nodes</:title>
        <div class="text-6xl text-center text-secondary"><%= length(@nodes) %></div>
      </.card>
    </div>

    <div class="grid xl:grid-cols-2 gap-6">
      <div class="div">
        <.h2>Pod Namespaces</.h2>
        <.chart id="pod-chart" type="doughnut" data={pod_data(@pods)} />
      </div>

      <.card>
        <:title>Recent Batteries</:title>
        <.table id="recent-batteries" rows={most_recent(@installed_batteries)}>
          <:col :let={battery} label="Type">
            <%= Naming.humanize(battery.type) %>
          </:col>
          <:col :let={battery} label="Group">
            <%= battery.group %>
          </:col>
        </.table>
      </.card>
    </div>
    """
  end
end
