defmodule ControlServerWeb.Live.KeycloakSnapshotShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.KeycloakActionsTable

  alias ControlServer.SnapshotApply.Keycloak

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"id" => id, "umbrella_id" => uid} = _params, _session, socket) do
    {:ok, socket |> assign_snapshot(id) |> assign_umbrella_id(uid)}
  end

  defp assign_snapshot(socket, id) do
    snap = Keycloak.get_preloaded_keycloak_snapshot!(id)
    assign(socket, :snapshot, snap)
  end

  defp assign_umbrella_id(socket, id) do
    assign(socket, :umbrella_id, id)
  end

  defp no_actions(assigns) do
    ~H"""
    <.flex class="justify-center">
      <div class="text-lg underline text-center">No Actions Needed</div>
    </.flex>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Keycloak Deploy" back_link={~p"/deploy/#{@umbrella_id}/show"}>
      <.flex>
        <.badge>
          <:item label="Status">{@snapshot.status}</:item>
          <:item label="Started">
            <.relative_display time={@snapshot.inserted_at} />
          </:item>
        </.badge>
      </.flex>
    </.page_header>

    <.panel title="Action Results">
      <.keycloak_action_table
        :if={@snapshot.keycloak_actions != []}
        rows={@snapshot.keycloak_actions}
      />
      <.no_actions :if={@snapshot.keycloak_actions == []} />
    </.panel>
    """
  end
end
