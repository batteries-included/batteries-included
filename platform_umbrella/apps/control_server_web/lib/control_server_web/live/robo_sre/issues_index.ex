defmodule ControlServerWeb.Live.RoboSRE.IssuesIndex do
  @moduledoc """
  LiveView for listing and filtering RoboSRE issues.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.RoboSRE.IssuesTable

  alias CommonCore.RoboSRE.HandlerType
  alias CommonCore.RoboSRE.IssueStatus
  alias CommonCore.RoboSRE.IssueType
  alias ControlServer.RoboSRE.Issues
  alias EventCenter.Database, as: DatabaseEventCenter

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = DatabaseEventCenter.subscribe(:issue)
    end

    {:ok,
     socket
     |> assign(:current_page, :magic)
     |> assign(:page_title, "RoboSRE Issues")
     |> assign_counts()}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    case Issues.list_issues(params) do
      {:ok, {issues, meta}} ->
        {:noreply,
         socket
         |> assign(:meta, meta)
         |> assign(:issues, issues)
         |> assign_counts()}

      {:error, meta} ->
        {:noreply,
         socket
         |> assign(:meta, meta)
         |> assign(:issues, [])
         |> assign_counts()}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("filter", params, socket) do
    # Filter out Phoenix LiveView internal params and empty values
    valid_fields = ~w(subject issue_type status handler)

    filters =
      params
      |> Map.take(valid_fields)
      |> Enum.reject(fn {_key, value} -> value == "" end)
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {{field, value}, index}, acc ->
        op = if field == "subject", do: "ilike", else: "=="

        Map.put(acc, to_string(index), %{
          "field" => field,
          "op" => op,
          "value" => value
        })
      end)

    flop_params = if Enum.empty?(filters), do: %{}, else: %{"filters" => filters}
    {:noreply, push_patch(socket, to: ~p"/robo_sre/issues?#{flop_params}")}
  end

  @impl Phoenix.LiveView
  def handle_info({action, %{} = _issue}, socket) when action in [:insert, :update, :delete] do
    # Refresh counts when issues are created, updated, or deleted
    {:noreply, assign_counts(socket)}
  end

  @impl Phoenix.LiveView
  def handle_info(_msg, socket) do
    {:noreply, socket}
  end

  defp assign_counts(socket) do
    socket
    |> assign(:total_issues_count, Issues.count_total_issues())
    |> assign(:open_issues_count, Issues.count_open_issues())
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="RoboSRE Issues" back_link={~p"/magic"}>
      <.badge>
        <:item label="Total Issues">{@total_issues_count}</:item>
        <:item label="Open Issues">{@open_issues_count}</:item>
      </.badge>
    </.page_header>

    <.panel title="Issues">
      <:menu>
        <.filter_form meta={@meta} />
      </:menu>

      <.issues_table rows={@issues} meta={@meta} />
    </.panel>
    """
  end

  defp filter_form(assigns) do
    ~H"""
    <form phx-change="filter" class="grid grid-cols-1 md:grid-cols-4 gap-4 w-full">
      <div>
        <.input
          type="text"
          name="subject"
          value={@meta.flop.filters |> get_filter_value("subject")}
          placeholder="Filter by subject..."
        />
      </div>

      <div>
        <.input
          type="select"
          name="issue_type"
          value={@meta.flop.filters |> get_filter_value("issue_type")}
          options={[{"All Issue Types", ""} | IssueType.options()]}
        />
      </div>

      <div>
        <.input
          type="select"
          name="status"
          value={@meta.flop.filters |> get_filter_value("status")}
          options={[{"All Statuses", ""} | IssueStatus.options()]}
        />
      </div>

      <div>
        <.input
          type="select"
          name="handler"
          value={@meta.flop.filters |> get_filter_value("handler")}
          options={[{"All Handlers", ""} | HandlerType.options()]}
        />
      </div>
    </form>
    """
  end

  defp get_filter_value(filters, field) when is_list(filters) do
    case Enum.find(filters, &(&1.field == String.to_atom(field))) do
      %{value: value} -> value
      _ -> ""
    end
  end

  defp get_filter_value(_, _), do: ""
end
