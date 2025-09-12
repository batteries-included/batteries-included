defmodule ControlServerWeb.RoboSRE.RemediationActionsTable do
  @moduledoc """
  Table component for displaying remediation plan actions.
  """
  use ControlServerWeb, :html

  alias CommonCore.RoboSRE.ActionType

  attr :actions, :list, required: true
  attr :id, :string, default: "remediation-actions-table"

  def remediation_actions_table(assigns) do
    ~H"""
    <.table id={@id} rows={Enum.with_index(@actions)}>
      <:col :let={{_action, index}} label="Step">
        <span class="font-mono text-sm">{index + 1}</span>
      </:col>

      <:col :let={{action, _index}} label="Action Type">
        {ActionType.label(action.action_type)}
      </:col>

      <:col :let={{action, _index}} label="Parameters">
        <.action_params_display action={action} />
      </:col>

      <:col :let={{action, _index}} label="Status">
        <.action_status_display action={action} />
      </:col>

      <:col :let={{action, _index}} label="Result">
        <.action_result_display action={action} />
      </:col>
    </.table>
    """
  end

  defp action_params_display(%{action: %{params: params}} = assigns) when params != %{} do
    assigns = assign(assigns, :params_list, Map.to_list(params))

    ~H"""
    <div class="space-y-1">
      <div :for={{key, value} <- @params_list} class="text-xs">
        <span class="font-medium text-gray-dark">{key}:</span>
        <span class="ml-1">{format_param_value(value)}</span>
      </div>
    </div>
    """
  end

  defp action_params_display(assigns) do
    ~H"""
    <span class="text-xs text-gray-light">No parameters</span>
    """
  end

  defp action_status_display(%{action: %{executed_at: nil}} = assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400">
      <.icon name={:clock} class="size-3" /> Pending
    </span>
    """
  end

  defp action_status_display(%{action: %{executed_at: executed_at, result: %{"success" => true}}} = assigns) do
    assigns = assign(assigns, :executed_at, executed_at)

    ~H"""
    <span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400">
      <.icon name={:check_circle} class="size-3" /> Success
    </span>
    """
  end

  defp action_status_display(%{action: %{executed_at: executed_at}} = assigns) do
    assigns = assign(assigns, :executed_at, executed_at)

    ~H"""
    <span class="inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400">
      <.icon name={:exclamation_triangle} class="size-3" /> Failed
    </span>
    """
  end

  defp action_result_display(%{action: %{result: nil}} = assigns) do
    ~H"""
    <span class="text-xs text-gray-light">Not executed</span>
    """
  end

  defp action_result_display(%{action: %{result: result}} = assigns) when is_map(result) do
    assigns = assign(assigns, :result_text, format_result(result))

    ~H"""
    <.truncate_tooltip value={@result_text} />
    """
  end

  defp action_result_display(assigns) do
    ~H"""
    <span class="text-xs text-gray-light">No result</span>
    """
  end

  defp format_param_value(value) when is_binary(value), do: value
  defp format_param_value(value) when is_map(value), do: inspect(value, limit: :infinity, pretty: true)
  defp format_param_value(value), do: inspect(value)

  defp format_result(%{"success" => true, "message" => message}), do: message
  defp format_result(%{"success" => false, "error" => error}), do: "Error: #{error}"
  defp format_result(%{"message" => message}), do: message
  defp format_result(result), do: inspect(result, limit: :infinity, pretty: true)
end
