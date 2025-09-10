defmodule ControlServerWeb.Live.RoboSRE.IssuesShow do
  @moduledoc """
  LiveView for showing RoboSRE issue details and remediation plans.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.RoboSRE.IssueStatusBadge
  import ControlServerWeb.RoboSRE.RemediationActionsTable

  alias CommonCore.RoboSRE.IssueType
  alias CommonCore.RoboSRE.SubjectType
  alias ControlServer.RoboSRE.Issues
  alias ControlServer.RoboSRE.RemediationPlans

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    issue = Issues.get_issue!(id)
    remediation_plans = RemediationPlans.find_remediation_plans_by_issue(id)

    {:ok,
     socket
     |> assign(:current_page, :magic)
     |> assign(:page_title, "Issue Details")
     |> assign(:issue, issue)
     |> assign(:remediation_plans, remediation_plans)
     |> assign(:selected_plan_index, 0)}
  end

  @impl Phoenix.LiveView
  def handle_event("select_plan", %{"index" => index}, socket) do
    {:noreply, assign(socket, :selected_plan_index, String.to_integer(index))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Issue Details" back_link={~p"/robo_sre/issues"}>
      <.issue_facts_section issue={@issue} />
    </.page_header>

    <.grid columns={[sm: 1, lg: 3]} class="gap-6">
      <.issue_details_panel issue={@issue} />
      <.trigger_params_panel issue={@issue} />
      <.remediation_plans_panel
        plans={@remediation_plans}
        selected_index={@selected_plan_index}
        class="lg:col-span-3"
      />
    </.grid>
    """
  end

  defp issue_facts_section(assigns) do
    ~H"""
    <.badge>
      <:item label="Status">
        <.issue_status_badge status={@issue.status} />
      </:item>
      <:item label="Created">
        <.relative_display time={@issue.inserted_at} />
      </:item>
      <:item label="Updated">
        <.relative_display time={@issue.updated_at} />
      </:item>
    </.badge>
    """
  end

  defp issue_details_panel(assigns) do
    ~H"""
    <.panel title="Issue Details">
      <.data_list>
        <:item title="Subject">{@issue.subject}</:item>
        <:item title="Subject Type">
          {SubjectType.label(@issue.subject_type)}
        </:item>
        <:item title="Issue Type">
          {IssueType.label(@issue.issue_type)}
        </:item>
        <:item title="Trigger">
          {trigger_label(@issue.trigger)}
        </:item>
        <:item title="Status">
          <.issue_status_badge status={@issue.status} />
        </:item>
        <:item :if={@issue.handler} title="Handler">
          {handler_label(@issue.handler)}
        </:item>
        <:item :if={@issue.resolved_at} title="Resolved At">
          <.relative_display time={@issue.resolved_at} />
        </:item>
        <:item title="Retry Count">{@issue.retry_count}</:item>
        <:item title="Max Retries">{@issue.max_retries}</:item>
      </.data_list>
    </.panel>
    """
  end

  defp trigger_params_panel(%{issue: %{trigger_params: params}} = assigns) when params != %{} do
    assigns = assign(assigns, :params_list, Map.to_list(params))

    ~H"""
    <.panel title="Trigger Parameters">
      <.data_list>
        <:item :for={{key, value} <- @params_list} title={key}>
          <.trigger_param_value value={value} />
        </:item>
      </.data_list>
    </.panel>
    """
  end

  defp trigger_params_panel(assigns) do
    ~H"""
    <.panel title="Trigger Parameters">
      <.light_text>No trigger parameters available</.light_text>
    </.panel>
    """
  end

  defp remediation_plans_panel(%{plans: []} = assigns) do
    ~H"""
    <.panel title="Remediation Plans" class={@class}>
      <.light_text>No remediation plans available for this issue</.light_text>
    </.panel>
    """
  end

  defp remediation_plans_panel(%{plans: [plan]} = assigns) do
    assigns = assign(assigns, :plan, plan)

    ~H"""
    <.panel title="Remediation Plan" class={@class}>
      <.remediation_plan_details plan={@plan} />
    </.panel>
    """
  end

  defp remediation_plans_panel(assigns) do
    ~H"""
    <.panel title="Remediation Plans" class={@class}>
      <.tab_bar variant="minimal">
        <:tab
          :for={{_plan, index} <- Enum.with_index(@plans)}
          selected={@selected_index == index}
          phx-click="select_plan"
          phx-value-index={index}
        >
          Plan {index + 1}
        </:tab>
      </.tab_bar>

      <div class="mt-6">
        <.remediation_plan_details plan={Enum.at(@plans, @selected_index)} />
      </div>
    </.panel>
    """
  end

  defp remediation_plan_details(%{plan: nil} = assigns) do
    ~H"""
    <.light_text>Plan not found</.light_text>
    """
  end

  defp remediation_plan_details(assigns) do
    ~H"""
    <div class="space-y-6">
      <.data_list
        variant="horizontal-bolded"
        data={[
          {"Created", relative_display_text(@plan.inserted_at)},
          {"Max Retries", @plan.max_retries},
          {"Retry Delay", "#{@plan.retry_delay_ms}ms"},
          {"Success Delay", "#{@plan.success_delay_ms}ms"},
          {"Current Action", @plan.current_action_index + 1}
        ]}
      />

      <div>
        <h4 class="text-sm font-medium text-gray-darkest dark:text-gray-lighter mb-3">
          Actions ({length(@plan.actions)})
        </h4>
        <.remediation_actions_table
          :if={@plan.actions != []}
          actions={@plan.actions}
          id={"plan-#{@plan.id}-actions"}
        />
        <.light_text :if={@plan.actions == []}>No actions defined</.light_text>
      </div>
    </div>
    """
  end

  defp trigger_param_value(%{value: value} = _assigns) when is_map(value) do
    assigns = %{value: inspect(value, limit: :infinity, pretty: true)}

    ~H"""
    <pre class="text-xs bg-gray-lightest dark:bg-gray-darkest p-2 rounded whitespace-pre-wrap">{@value}</pre>
    """
  end

  defp trigger_param_value(%{value: value} = _assigns) when is_list(value) do
    assigns = %{value: inspect(value, limit: :infinity, pretty: true)}

    ~H"""
    <pre class="text-xs bg-gray-lightest dark:bg-gray-darkest p-2 rounded whitespace-pre-wrap">{@value}</pre>
    """
  end

  defp trigger_param_value(%{value: value} = _assigns) do
    assigns = %{value: to_string(value)}

    ~H"""
    <span>{@value}</span>
    """
  end

  defp trigger_label(trigger) do
    trigger
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp handler_label(nil), do: "Not assigned"

  defp handler_label(handler) do
    handler
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp relative_display_text(datetime) do
    CommonCore.Util.Time.from_now(datetime)
  end
end
