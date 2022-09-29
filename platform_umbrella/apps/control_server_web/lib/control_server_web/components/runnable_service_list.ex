defmodule ControlServerWeb.RunnableServiceList do
  use ControlServerWeb, :component

  import CommonUI.Icons.Misc

  alias Phoenix.Naming

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:base_services, fn -> [] end)
    |> assign_new(:runnable_services, fn -> [] end)
  end

  defp assign_matched_runnable(assigns) do
    base = Map.get(assigns, :base_services, [])
    runnable = Map.get(assigns, :runnable_services, [])

    matched =
      Enum.map(runnable, fn runnable ->
        running = Enum.find(base, fn bs -> bs.service_type == runnable.service_type end)
        {runnable, running}
      end)

    assign(assigns, :matched_runnable, matched)
  end

  def services_table(assigns) do
    assigns = assigns |> assign_defaults() |> assign_matched_runnable()

    ~H"""
    <div>
      <.table id="runnable-services-table" rows={@matched_runnable}>
        <:col :let={{service, _}} label="Service Type">
          <%= Naming.humanize(service.service_type) %>
        </:col>

        <:action :let={{service, running}}>
          <%= if running == nil do %>
            <.start_button runnable_service={service} />
          <% else %>
            <.running />
          <% end %>
        </:action>
      </.table>
    </div>
    """
  end

  def start_button(assigns) do
    ~H"""
    <.button phx-click={:start} phx-value-service-type={@runnable_service.service_type}>
      Start Service
    </.button>
    """
  end

  defp running(assigns) do
    ~H"""
    <div class="flex">
      <div class="flex-initial">
        Started
      </div>
      <div class="flex-none ml-5">
        <.check_mark class="text-shamrock-500" />
      </div>
    </div>
    """
  end
end
