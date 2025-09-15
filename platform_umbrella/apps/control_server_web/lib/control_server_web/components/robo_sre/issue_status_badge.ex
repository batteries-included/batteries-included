defmodule ControlServerWeb.RoboSRE.IssueStatusBadge do
  @moduledoc """
  Component for displaying RoboSRE issue status badges.
  """
  use ControlServerWeb, :html

  alias CommonCore.RoboSRE.IssueStatus

  attr :status, :atom, required: true
  attr :class, :any, default: nil

  def issue_status_badge(assigns) do
    ~H"""
    <span class={[status_badge_class(@status), @class]}>
      <.icon name={status_icon(@status)} class="size-3" />
      {IssueStatus.label(@status)}
    </span>
    """
  end

  defp status_badge_class(:detected) do
    [
      "inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full",
      "bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400"
    ]
  end

  defp status_badge_class(:analyzing) do
    [
      "inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full",
      "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400"
    ]
  end

  defp status_badge_class(:planning) do
    [
      "inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full",
      "bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-400"
    ]
  end

  defp status_badge_class(:remediating) do
    [
      "inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full",
      "bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-400"
    ]
  end

  defp status_badge_class(:verifying) do
    [
      "inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full",
      "bg-indigo-100 text-indigo-800 dark:bg-indigo-900/20 dark:text-indigo-400"
    ]
  end

  defp status_badge_class(:resolved) do
    [
      "inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full",
      "bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400"
    ]
  end

  defp status_badge_class(:failed) do
    [
      "inline-flex items-center gap-1 px-2 py-1 text-xs font-medium rounded-full",
      "bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400"
    ]
  end

  defp status_badge_class(_), do: status_badge_class(:detected)

  defp status_icon(:detected), do: :eye
  defp status_icon(:analyzing), do: :magnifying_glass
  defp status_icon(:planning), do: :light_bulb
  defp status_icon(:remediating), do: :wrench_screwdriver
  defp status_icon(:verifying), do: :shield_check
  defp status_icon(:resolved), do: :check_circle
  defp status_icon(:failed), do: :exclamation_triangle
  defp status_icon(_), do: :question_mark_circle
end
