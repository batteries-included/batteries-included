defmodule ControlServerWeb.KnativeDisplay do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.Chart
  import ControlServerWeb.ConditionsDisplay

  def service_display(assigns) do
    ~H"""
    <.traffic_display :if={length(traffic(@service)) > 1} traffic={traffic(@service)} />

    <.grid columns={[sm: 1, lg: 2]}>
      <.conditions_display conditions={conditions(@service)} />
      <.revisions_display revisions={@revisions} />
    </.grid>
    """
  end

  defp traffic(service) do
    get_in(service, ~w(status traffic)) || []
  end

  defp actual_replicas(revision) do
    get_in(revision, ~w(status actualReplicas)) || 0
  end

  defp traffic_chart_data(traffic_list) do
    dataset = %{
      data: Enum.map(traffic_list, &get_in(&1, ~w(percent))),
      label: "Traffic"
    }

    labels = Enum.map(traffic_list, &get_in(&1, ~w(revisionName)))

    %{labels: labels, datasets: [dataset]}
  end

  defp traffic_display(assigns) do
    ~H"""
    <.panel title="Traffic Split">
      <.grid columns={[sm: 1, lg: 2]} class="items-center">
        <.table rows={@traffic} id="traffic-table">
          <:col :let={split} label="Revision"><%= Map.get(split, "revisionName", "") %></:col>
          <:col :let={split} label="Percent"><%= Map.get(split, "percent", 0) %></:col>
        </.table>
        <.chart class="max-h-[32rem] mx-auto" id="traffic-chart" data={traffic_chart_data(@traffic)} />
      </.grid>
    </.panel>
    """
  end

  def revisions_display(assigns) do
    ~H"""
    <.panel title="Revisions">
      <.table rows={@revisions} id="revisions-table">
        <:col :let={rev} label="Name"><%= name(rev) %></:col>
        <:col :let={rev} label="Replicas"><%= actual_replicas(rev) %></:col>
        <:col :let={rev} label="Created"><%= creation_timestamp(rev) %></:col>
      </.table>
    </.panel>
    """
  end
end
