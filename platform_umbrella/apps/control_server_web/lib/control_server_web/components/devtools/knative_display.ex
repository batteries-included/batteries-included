defmodule ControlServerWeb.KnativeDisplay do
  use ControlServerWeb, :component

  import CommonUI.Table
  import ControlServerWeb.LeftMenuLayout

  import K8s.Resource.FieldAccessors

  def service_display(assigns) do
    ~H"""
    <.h3>Service Properties</.h3>
    <.body_section>
      <div class="px-4 py-5 sm:px-6">
        <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-2">
          <.definition label="Service Name" value={name(@service)} />
          <.definition label="Namespace" value={namespace(@service)} />
          <.definition label="Concurrency Limit" value={max_concurrency(@service)} />
          <.definition label="URL">
            <.link to={service_url(@service)}><%= service_url(@service) %></.link>
          </.definition>
        </dl>
      </div>
    </.body_section>
    <.h3>Traffic Split</.h3>
    <.traffic_table traffic={traffic(@service)} />
    <.h3>Status Gates</.h3>
    <.status_table service={@service} />
    """
  end

  defp definition(assigns) do
    assigns =
      assigns |> assign_new(:value, fn -> nil end) |> assign_new(:inner_block, fn -> nil end)

    ~H"""
    <div class="sm:col-span-1">
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

  defp status_table(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>
            Type
          </.th>
          <.th>
            Status
          </.th>
          <.th>
            Time
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for condition <- conditions(@service) do %>
          <.condition_row condition={condition} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp condition_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= Map.get(@condition, "type", "") %>
      </.td>
      <.td>
        <%= Map.get(@condition, "status", "") %>
      </.td>
      <.td>
        <%= Map.get(@condition, "lastTransitionTime", "") %>
      </.td>
    </.tr>
    """
  end

  defp traffic_table(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>
            Revision
          </.th>
          <.th>
            Percent
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for split <- @traffic do %>
          <.traffic_row split={split} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp traffic_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @split["revisionName"] %>
      </.td>
      <.td>
        <%= @split["percent"] %>
      </.td>
    </.tr>
    """
  end

  def revisions_display(assigns) do
    ~H"""
    <.h3>Revisions</.h3>
    <.revisions_table revisions={@revisions} />
    """
  end

  defp revisions_table(assigns) do
    ~H"""
    <.table>
      <.thead>
        <.tr>
          <.th>
            Name
          </.th>
          <.th>
            Replicas
          </.th>
          <.th>
            Created
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for revision <- @revisions do %>
          <.revision_row revision={revision} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp revision_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= name(@revision) %>
      </.td>
      <.td>
        <%= actual_replicas(@revision) %>
      </.td>
      <.td>
        <%= creation_timestamp(@revision) %>
      </.td>
    </.tr>
    """
  end
end
