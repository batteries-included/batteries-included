defmodule ControlServerWeb.ResourceComponents do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  alias CommonCore.Util.Time

  def label_section(assigns) do
    ~H"""
    <.panel title="Labels">
      <.data_horizontal_plain data={labels(@resource)} />
    </.panel>
    """
  end

  attr :resource, :map, required: true

  def pod_containers_section(assigns) do
    assigns = assign(assigns, :container_statuses, container_statuses(assigns.resource))

    ~H"""
    <.panel class="py-0 mt-8" title="Containers">
      <.table id="pod-containers" rows={@container_statuses}>
        <:col :let={cs} label="Name"><%= Map.get(cs, "name", "") %></:col>
        <:col :let={cs} label="Image"><%= Map.get(cs, "image", "") %></:col>
        <:col :let={cs} label="Started"><.status_icon status={Map.get(cs, "started", false)} /></:col>
        <:col :let={cs} label="Ready"><.status_icon status={Map.get(cs, "ready", false)} /></:col>
        <:col :let={cs} label="Restart Count">
          <%= Map.get(cs, "restartCount", 0) %>
        </:col>
        <:action :let={cs}>
          <.action_icon
            to={
              resource_show_path(@resource, %{"log" => true, "container" => Map.get(cs, "name", "")})
            }
            icon={:document_text}
            tooltip="Logs"
            id={"show_resource_" <> to_html_id(@resource)}
          />
        </:action>
      </.table>
    </.panel>
    """
  end

  def events_section(assigns) do
    ~H"""
    <.panel variant="gray" title="Events">
      <.table :if={@events != []} transparent rows={@events}>
        <:col :let={event} label="Reason"><%= get_in(event, ~w(reason)) %></:col>
        <:col :let={event} label="Message"><%= event |> get_in(~w(message)) |> truncate() %></:col>
        <:col :let={event} label="Type"><%= get_in(event, ~w(type)) %></:col>
        <:col :let={event} label="First Time">
          <%= Time.format_iso8601(event["firstTimestamp"], "{RFC822z}") %>
        </:col>
        <:col :let={event} label="Count"><%= get_in(event, ~w(count)) %></:col>
      </.table>

      <.light_text :if={@events == []}>No events</.light_text>
    </.panel>
    """
  end

  def status_icon(%{status: status} = assigns) when status in ["true", true, :ok] do
    ~H"""
    <div class="flex items-center gap-2">
      <Heroicons.check_circle class="w-6 h-6 text-primary-600" />
      <div class="flex-initial">
        Started
      </div>
    </div>
    """
  end

  def status_icon(assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <Heroicons.x_circle class="w-6 h-6 text-danger-600 dark:text-danger-500" />
      <div class="flex-initial">
        False
      </div>
    </div>
    """
  end

  attr :resource, :map
  attr :namespace, :string
  attr :phase, :string
  attr :service_account, :string
  attr :start_time, :string

  def pod_facts_section(%{phase: _} = assigns) do
    ~H"""
    <.data_horizontal_bordered>
      <:item title="Namespace"><%= @namespace %></:item>
      <:item title="Phase"><%= @phase %></:item>
      <:item title="Account"><%= @service_account %></:item>
      <:item title="Started"><%= @start_time %></:item>
    </.data_horizontal_bordered>
    """
  end

  def pod_facts_section(assigns) do
    assigns
    |> assign_new(:phase, fn -> get_in(assigns.resource, ~w|status phase|) end)
    |> assign_new(:start_time, fn ->
      case get_in(assigns.resource, ~w|status startTime|) do
        nil ->
          "Not found"

        start_time ->
          CommonCore.Util.Time.format_iso8601(start_time, "{Mshort} {D}, {h24}:{m}:{s}")
      end
    end)
    |> assign_new(:service_account, fn -> get_in(assigns.resource, ~w|spec serviceAccount|) end)
    |> pod_facts_section()
  end

  attr :resource, :map
  attr :logs, :list

  def logs_modal(assigns) do
    ~H"""
    <PC.modal :if={@logs != nil} title="Logs" max_width="xl">
      <.light_text class="mb-5"><%= name(@resource) %></.light_text>
      <div
        id="scroller"
        style="max-height: 70vh"
        class="max-h-full rounded bg-astral-900 min-h-16"
        phx-hook="ResourceLogsModal"
      >
        <code class="block p-3 overflow-x-scroll text-white">
          <p :for={line <- @logs || []} class="mb-3 leading-none whitespace-normal">
            <span class="inline-block px-2 font-mono text-sm bg-astral-400 bg-opacity-20">
              <%= line %>
            </span>
          </p>
          <div id="anchor"></div>
        </code>
      </div>
    </PC.modal>
    """
  end
end
