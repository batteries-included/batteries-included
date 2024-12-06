defmodule ControlServerWeb.Live.UmbrellaSnapshotShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.SnapshotApply.Umbrella
  alias ControlServer.SnapshotApply.UmbrellaSnapshot

  def mount(%{"id" => id} = _params, _session, socket) do
    {:ok, assign_snapshot(socket, id)}
  end

  defp assign_snapshot(socket, id) do
    assign(socket, :snapshot, Umbrella.get_loaded_snapshot!(id))
  end

  defp total_status(%{kube_snapshot: nil} = _snapshot) do
    "Starting"
  end

  defp total_status(%UmbrellaSnapshot{kube_snapshot: kube_snap, keycloak_snapshot: nil} = _snapshot) do
    kube_snap.status
  end

  defp total_status(%UmbrellaSnapshot{kube_snapshot: kube_snap, keycloak_snapshot: key_snap} = _snapshot) do
    "#{kube_snap.status} / #{key_snap.status}"
  end

  defp kube_show_url(%{id: id, kube_snapshot: %{id: kube_id}} = _snapshot) do
    ~p(/deploy/#{id}/kube/#{kube_id})
  end

  defp kube_show_url(%{id: id} = _snapshot) do
    ~p(/deploy/#{id}/show)
  end

  defp kecloak_show_url(%{id: id, keycloak_snapshot: %{id: keycloak_id}} = _snapshot) do
    ~p(/deploy/#{id}/keycloak/#{keycloak_id})
  end

  defp kecloak_show_url(%{id: id} = _snapshot) do
    ~p(/deploy/#{id}/show)
  end

  def render(assigns) do
    ~H"""
    <.page_header title="Show Deploy" back_link={~p"/deploy"}>
      <.flex>
        <.badge>
          <:item label="Status">{total_status(@snapshot)}</:item>
          <:item label="Started">
            <.relative_display time={@snapshot.inserted_at} />
          </:item>
        </.badge>
      </.flex>
    </.page_header>

    <.grid columns={2}>
      <.a :if={@snapshot.kube_snapshot != nil} variant="bordered" navigate={kube_show_url(@snapshot)}>
        Kubernetes Deploy
      </.a>

      <.a
        :if={@snapshot.keycloak_snapshot != nil}
        variant="bordered"
        navigate={kecloak_show_url(@snapshot)}
      >
        Keycloak Deploy
      </.a>
    </.grid>
    """
  end
end
