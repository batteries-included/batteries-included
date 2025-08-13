defmodule ControlServerWeb.TrivyReports.RBACChecksTable do
  @moduledoc false
  use ControlServerWeb, :html

  def rbac_checks_table(assigns) do
    ~H"""
    <%= if @rows && length(@rows) > 0 do %>
      <.table id="rbac-checks-table" rows={@rows}>
        <:col :let={check} label="Severity">
          <span class={[
            "inline-block px-2 py-1 text-xs font-medium rounded",
            severity_class(get_in(check, ~w(severity)))
          ]}>
            {get_in(check, ~w(severity))}
          </span>
        </:col>
        <:col :let={check} label="Check ID">{get_in(check, ~w(checkID))}</:col>
        <:col :let={check} label="Title">
          <.truncate_tooltip value={get_in(check, ~w(title))} />
        </:col>
        <:col :let={check} label="Category">{get_in(check, ~w(category))}</:col>
        <:col :let={check} label="Status">
          <span class={[
            "inline-block px-2 py-1 text-xs font-medium rounded",
            if get_in(check, ~w(success)) do
              "bg-green-100 text-green-800"
            else
              "bg-red-100 text-red-800"
            end
          ]}>
            {if get_in(check, ~w(success)), do: "PASS", else: "FAIL"}
          </span>
        </:col>
        <:col :let={check} label="Description">
          <.truncate_tooltip value={get_in(check, ~w(description))} />
        </:col>
        <:col :let={check} label="Messages">
          <div class="space-y-1">
            <%= for message <- (get_in(check, ~w(messages)) || []) do %>
              <div class="text-sm text-gray-600 p-2 bg-gray-50 rounded">
                <.truncate_tooltip value={message} />
              </div>
            <% end %>
          </div>
        </:col>
        <:col :let={check} label="Remediation">
          <.truncate_tooltip value={get_in(check, ~w(remediation))} />
        </:col>
      </.table>
    <% else %>
      <div class="text-center text-gray-500 py-8">
        <div class="text-xl">
          No RBAC issues found
        </div>
        <div class="text-sm mt-2">
          This is a good thing! Your cluster RBAC configuration doesn't have any security issues.
        </div>
      </div>
    <% end %>
    """
  end

  defp severity_class("CRITICAL"), do: "bg-red-100 text-red-800"
  defp severity_class("HIGH"), do: "bg-orange-100 text-orange-800"
  defp severity_class("MEDIUM"), do: "bg-yellow-100 text-yellow-800"
  defp severity_class("LOW"), do: "bg-blue-100 text-blue-800"
  defp severity_class(_), do: "bg-gray-100 text-gray-800"
end
