defmodule ControlServerWeb.Live.MagicHome do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.UmbrellaSnapshotsTable

  alias ControlServer.SnapshotApply.Umbrella

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign_snapshots(socket)}
  end

  def assign_snapshots(socket) do
    snaps = Umbrella.latest_umbrella_snapshots()
    assign(socket, :snapshots, snaps)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Magic">
      <:right_side>
        <PC.button
          label="Manage Batteries"
          color="light"
          to={~p"/batteries/magic"}
          link_type="live_redirect"
        />
      </:right_side>
    </.page_header>
    <.grid columns={%{sm: 1, lg: 2}} class="w-full">
      <.panel>
        <:title>Deploys</:title>
        <:top_right>
          <.flex>
            <.a navigate={~p"/snapshot_apply"}>View All</.a>
          </.flex>
        </:top_right>
        <.umbrella_snapshots_table abbridged snapshots={@snapshots} />
      </.panel>
      <.flex class="flex-col items-stretch justify-start">
        <.panel>
          <.a navigate={~p"/history/timeline"} variant="styled">Timeline</.a>
        </.panel>
        <.panel>
          <.a navigate={~p"/content_addressable"} variant="styled">Content Addressable Storage</.a>
        </.panel>
        <.panel>
          <.a navigate={~p"/stale"} variant="styled">Delete Queue</.a>
        </.panel>
        <.panel>
          <.a navigate={~p"/deleted_resources"} variant="styled">Deleted Resources</.a>
        </.panel>
        <.panel>
          <.a href="http://home.127.0.0.1.ip.batteriesincl.com:4900/" variant="external">
            Batteries Included Home
          </.a>
        </.panel>
      </.flex>
    </.grid>
    """
  end
end
