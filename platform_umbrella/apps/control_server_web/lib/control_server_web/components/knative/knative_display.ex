defmodule ControlServerWeb.KnativeDisplay do
  use ControlServerWeb, :html

  import ControlServerWeb.ConditionsDisplay
  import ControlServerWeb.Chart

  import K8s.Resource.FieldAccessors
  alias Jason

  def service_display(assigns) do
    ~H"""
    <.card>
      <div class="px-4 py-5 sm:px-6">
        <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-3">
          <.definition label="Service Name" value={name(@service)} />
          <.definition label="Namespace" value={namespace(@service)} />
          <.definition label="Concurrency Limit" value={max_concurrency(@service)} />
          <.definition label="URL" class="sm:col-span-3">
            <.a href={service_url(@service)} variant="external">
              <%= service_url(@service) %>
            </.a>
          </.definition>
        </dl>
      </div>
    </.card>
    <.traffic_display traffic={traffic(@service)} />
    <.h2>Status Gates</.h2>
    <.status_table service={@service} />
    """
  end

  defp definition(assigns) do
    assigns =
      assigns
      |> assign_new(:value, fn -> nil end)
      |> assign_new(:inner_block, fn -> nil end)
      |> assign_new(:class, fn -> "sm:col-span-1" end)

    ~H"""
    <div class={@class}>
      <dt class="text-md font-medium text-astral-500"><%= @label %></dt>
      <dd class="mt-1 text-md text-gray-900">
        <%= if @value do %>
          <%= @value %>
        <% else %>
          <%= if @inner_block do %>
            <%= render_slot(@inner_block) %>
          <% end %>
        <% end %>
      </dd>
    </div>
    """
  end

  defp traffic(service) do
    get_in(service, ~w(status traffic)) || []
  end

  defp max_concurrency(service) do
    get_in(service, ~w(spec template spec containerConcurrency)) || 0
  end

  defp service_url(service) do
    get_in(service, ~w(status url))
  end

  defp conditions(service) do
    get_in(service, ~w(status conditions)) || []
  end

  defp creation_timestamp(resource) do
    get_in(resource, ~w(metadata creationTimestamp)) || ""
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

  defp status_table(assigns) do
    ~H"""
    <.conditions_display conditions={conditions(@service)} />
    """
  end

  defp traffic_display(%{traffic: []} = assigns), do: ~H||
  defp traffic_display(%{traffic: [_]} = assigns), do: ~H||

  defp traffic_display(%{traffic: [_ | _]} = assigns) do
    ~H"""
    <.h2>Traffic Split</.h2>
    <div class="grid grid-cols-1 md:grid-cols-2">
      <.table rows={@traffic} id="traffic-table">
        <:col :let={split} label="Revision"><%= Map.get(split, "revisionName", "") %></:col>
        <:col :let={split} label="Percent"><%= Map.get(split, "percent", 0) %></:col>
      </.table>
      <.chart class="max-h-[32rem] mx-auto" id="traffic-chart" data={traffic_chart_data(@traffic)} />
    </div>
    """
  end

  def revisions_display(assigns) do
    ~H"""
    <.h2>Revisions</.h2>
    <.revisions_table revisions={@revisions} />
    """
  end

  defp revisions_table(assigns) do
    ~H"""
    <.table rows={@revisions} id="revisions-table">
      <:col :let={rev} label="Name"><%= name(rev) %></:col>
      <:col :let={rev} label="Replicas"><%= actual_replicas(rev) %></:col>
      <:col :let={rev} label="Created"><%= creation_timestamp(rev) %></:col>
    </.table>
    """
  end
end
