defmodule ControlServerWeb.KnativeDisplay do
  use ControlServerWeb, :html

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.ConditionsDisplay

  import K8s.Resource.FieldAccessors

  def service_display(assigns) do
    ~H"""
    <.body_section>
      <div class="px-4 py-5 sm:px-6">
        <dl class="grid grid-cols-1 gap-x-4 gap-y-8 sm:grid-cols-3">
          <.definition label="Service Name" value={name(@service)} />
          <.definition label="Namespace" value={namespace(@service)} />
          <.definition label="Concurrency Limit" value={max_concurrency(@service)} />
          <.definition label="URL" class="sm:col-span-3">
            <.link href={service_url(@service)} type="external"><%= service_url(@service) %></.link>
          </.definition>
        </dl>
      </div>
    </.body_section>
    <.section_title>Traffic Split</.section_title>
    <.traffic_table traffic={traffic(@service)} />
    <.section_title>Status Gates</.section_title>
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

  defp status_table(assigns) do
    ~H"""
    <.conditions_display conditions={conditions(@service)} />
    """
  end

  defp traffic_table(assigns) do
    ~H"""
    <.table rows={@traffic} id="traffic-table">
      <:col :let={split} label="Revision"><%= Map.get(split, "revisionName", "") %></:col>
      <:col :let={split} label="Percent"><%= Map.get(split, "percent", "") %></:col>
    </.table>
    """
  end

  def revisions_display(assigns) do
    ~H"""
    <.section_title>Revisions</.section_title>
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
