defmodule ControlServerWeb.Live.StateSummary do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias EventCenter.SystemStateSummary, as: SummaryEventCenter

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = SummaryEventCenter.subscribe()
    end

    {:ok, socket |> assign_state_summary() |> assign_page_title()}
  end

  defp assign_state_summary(socket) do
    state_summary = KubeServices.SystemState.Summarizer.cached()

    assign(socket,
      state_summary: state_summary,
      upgrade_days_of_week: CommonCore.StateSummary.Core.upgrade_days_of_week(state_summary),
      upgrade_control_server:
        state_summary
        |> Map.get(:stable_versions_report, %{})
        |> Kernel.||(%{})
        |> Map.get(:control_server, CommonCore.Defaults.Images.control_server_image())
    )
  end

  defp assign_page_title(socket) do
    socket
    |> assign(page_title: "State Summary")
    |> assign(current_page: :magic)
  end

  def handle_info(_, socket) do
    # Doesn't matter what the event is, just update the state summary
    {:noreply, assign_state_summary(socket)}
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/magic"}>
      Captured At: {Calendar.strftime(
        @state_summary.captured_at || DateTime.utc_now(),
        "%b %-d, %-I:%M%p"
      )}
    </.page_header>

    <.grid columns={%{sm: 1, xl: 2}}>
      <.panel title="Batteries">
        <ul>
          <%= for battery <- @state_summary.batteries do %>
            <li>{battery.type}</li>
          <% end %>
        </ul>
      </.panel>
      <.panel :if={@state_summary.install_status} title="Install Status">
        <.data_list>
          <:item title="Status">{@state_summary.install_status.status}</:item>
          <:item title="Message">{@state_summary.install_status.message}</:item>
          <:item title="Expires">{@state_summary.install_status.exp}</:item>
        </.data_list>
      </.panel>

      <.panel title="Stable Versions">
        <.data_list>
          <:item title="Current Control Server Image">
            {CommonCore.Defaults.Images.control_server_image()}
          </:item>
          <:item title="Stable Control Server Image">
            {@upgrade_control_server}
          </:item>
          <:item :for={{day, avail} <- @upgrade_days_of_week} title={"Can upgrade on #{day}"}>
            {avail}
          </:item>
        </.data_list>
      </.panel>
      <.panel :if={@state_summary.keycloak_state} title="Keycloak Status">
        <ul>
          <%= for realm <- (@state_summary.keycloak_state.realms || [] ) do %>
            <li>{realm.displayName}</li>
          <% end %>
        </ul>
      </.panel>
      <.panel :if={@state_summary.kube_state} title="Kube Status">
        <.data_list>
          <:item :for={{type, res} <- @state_summary.kube_state} title={type}>
            {length(res)}
          </:item>
        </.data_list>
      </.panel>
    </.grid>
    """
  end
end
