defmodule HomeBaseWeb.Live.Admin.InstallationsShow do
  @moduledoc false

  use HomeBaseWeb, :live_view

  import HomeBaseWeb.Admin.UsageReportsTable

  alias HomeBase.CustomerInstalls
  alias HomeBase.ET

  def mount(%{"id" => id}, _session, socket) do
    installation = CustomerInstalls.get_installation!(id)
    usage_reports = ET.list_recent_usage_reports(installation)
    host_report = ET.get_most_recent_host_report(installation)

    {:ok,
     socket
     |> assign(:installation, installation)
     |> assign(:usage_reports, usage_reports)
     |> assign(:host_report, host_report)}
  end

  def render(assigns) do
    ~H"""
    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Installation">
        <.data_list>
          <:item title="ID">{@installation.id}</:item>
          <:item title="Slug">{@installation.slug}</:item>
          <:item :if={@installation.team} title="Team">
            <.a navigate={~p"/admin/teams/#{@installation.team.id}/"} variant="underlined">
              {@installation.team.name}
            </.a>
          </:item>
          <:item title="User">
            <.a
              :if={@installation.user}
              navigate={~p"/admin/users/#{@installation.user.id}/"}
              variant="underlined"
            >
              {@installation.user.email}
            </.a>
            <div :if={@installation.user == nil}>Only owned by Team</div>
          </:item>
        </.data_list>
      </.panel>
      <.panel title="Hosts">
        <.data_list :if={@host_report && @host_report.report}>
          <:item title="Control Server Host">
            {@host_report.report.control_server_host}
          </:item>
        </.data_list>
      </.panel>
      <.panel title="Usage Reports" class="lg:col-span-2">
        <.usage_reports_table rows={@usage_reports} />
      </.panel>
    </.grid>
    """
  end
end
