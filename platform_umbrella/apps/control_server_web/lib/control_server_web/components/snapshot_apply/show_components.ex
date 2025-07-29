defmodule ControlServerWeb.SnapshotApply.ShowComponents do
  @moduledoc """
  Reusable components for the unified snapshot apply show page.
  """
  use ControlServerWeb, :html

  @doc """
  Displays the snapshot facts section with status and timing information.
  """
  attr :snapshot, :map, required: true

  def snapshot_facts_section(%{} = assigns) do
    ~H"""
    <.badge>
      <:item label="Status">{total_status(@snapshot)}</:item>
      <:item label="Started">
        <.relative_display time={@snapshot.inserted_at} />
      </:item>
    </.badge>
    """
  end

  @doc """
  Displays the navigation panel with tabs for different snapshot views.
  """
  attr :live_action, :atom, required: true
  attr :snapshot, :map, required: true

  def link_panel(assigns) do
    ~H"""
    <.panel variant="gray" class="lg:order-last">
      <.tab_bar variant="navigation">
        <:tab selected={@live_action == :overview} patch={~p"/deploy/#{@snapshot.id}/show"}>
          Overview
        </:tab>
        <:tab
          :if={@snapshot.kube_snapshot != nil}
          selected={@live_action == :kube}
          patch={~p"/deploy/#{@snapshot.id}/kube"}
        >
          Kubernetes
        </:tab>
        <:tab
          :if={@snapshot.keycloak_snapshot != nil}
          selected={@live_action == :keycloak}
          patch={~p"/deploy/#{@snapshot.id}/keycloak"}
        >
          Keycloak
        </:tab>
      </.tab_bar>
    </.panel>
    """
  end

  @doc """
  Displays a message when no keycloak actions are needed.
  """
  def no_actions(assigns) do
    ~H"""
    <.flex class="justify-center">
      <div class="text-lg underline text-center">No Actions Needed</div>
    </.flex>
    """
  end

  # Helper functions

  defp total_status(%{kube_snapshot: nil} = _snapshot) do
    "Starting"
  end

  defp total_status(%{kube_snapshot: kube_snap, keycloak_snapshot: nil} = _snapshot) do
    kube_snap.status
  end

  defp total_status(%{kube_snapshot: kube_snap, keycloak_snapshot: key_snap} = _snapshot) do
    "#{kube_snap.status} / #{key_snap.status}"
  end
end
