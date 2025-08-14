defmodule ControlServerWeb.Trivy.TrivyShowTable do
  @moduledoc """
  Unified table component for displaying detailed findings within Trivy reports.

  This component handles all types of Trivy report details (vulnerabilities,
  secrets, checks, etc.) with appropriate styling and formatting.
  """
  use ControlServerWeb, :html

  def trivy_show_table(assigns) do
    ~H"""
    <%= if @rows && length(@rows) > 0 do %>
      <%= case @type do %>
        <% :vulnerabilities -> %>
          <.table id={@id} rows={@rows}>
            <:col :let={vuln} label="Severity">
              <span class={[
                "inline-block px-2 py-1 text-xs font-medium rounded",
                severity_class(get_in(vuln, ~w(severity)))
              ]}>
                {get_in(vuln, ~w(severity))}
              </span>
            </:col>
            <:col :let={vuln} label="Title">
              <.link href={get_in(vuln, ~w(primaryLink))}>
                <.truncate_tooltip value={get_in(vuln, ~w(title))} />
              </.link>
            </:col>
            <:col :let={vuln} label="Software">
              <.truncate_tooltip value={get_in(vuln, ~w(resource))} />
            </:col>
            <:col :let={vuln} label="Used">{get_in(vuln, ~w(installedVersion))}</:col>
            <:col :let={vuln} label="Fixed">{get_in(vuln, ~w(fixedVersion))}</:col>
            <:col :let={vuln} label="Extended Info">
              <.a href={get_in(vuln, ~w(primaryLink))} variant="external">
                Show
              </.a>
            </:col>
          </.table>
        <% :exposed_secrets -> %>
          <.table id={@id} rows={@rows}>
            <:col :let={secret} label="Severity">
              <span class={[
                "inline-block px-2 py-1 text-xs font-medium rounded",
                severity_class(get_in(secret, ~w(severity)))
              ]}>
                {get_in(secret, ~w(severity))}
              </span>
            </:col>
            <:col :let={secret} label="Title">
              <.truncate_tooltip value={get_in(secret, ~w(title))} />
            </:col>
            <:col :let={secret} label="Rule ID">{get_in(secret, ~w(ruleID))}</:col>
            <:col :let={secret} label="Category">{get_in(secret, ~w(category))}</:col>
            <:col :let={secret} label="Match">
              <.truncate_tooltip value={get_in(secret, ~w(match))} />
            </:col>
          </.table>
        <% :rbac_checks -> %>
          <.table id={@id} rows={@rows}>
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
        <% :config_audit_checks -> %>
          <.table id={@id} rows={@rows}>
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
            <:col :let={check} label="Description">
              <.truncate_tooltip value={get_in(check, ~w(description))} />
            </:col>
            <:col :let={check} label="Remediation">
              <.truncate_tooltip value={get_in(check, ~w(remediation))} />
            </:col>
          </.table>
        <% :infra_checks -> %>
          <.table id={@id} rows={@rows}>
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
            <:col :let={check} label="Description">
              <.truncate_tooltip value={get_in(check, ~w(description))} />
            </:col>
          </.table>
        <% :sbom_components -> %>
          <.table id={@id} rows={@rows}>
            <:col :let={component} label="Name">
              <.truncate_tooltip value={get_in(component, ~w(name))} />
            </:col>
            <:col :let={component} label="Version">{get_in(component, ~w(version))}</:col>
            <:col :let={component} label="Type">{get_in(component, ~w(type))}</:col>
            <:col :let={component} label="License">
              <.component_licenses licenses={get_in(component, ~w(licenses))} />
            </:col>
          </.table>
      <% end %>
    <% else %>
      <div class="text-center text-gray-500 py-8">
        <div class="text-xl">
          {empty_message(@type)}
        </div>
        <div class="text-sm mt-2">
          {empty_description(@type)}
        </div>
      </div>
    <% end %>
    """
  end

  defp severity_class("CRITICAL"), do: "bg-red-100 text-red-800"
  defp severity_class("HIGH"), do: "bg-orange-100 text-orange-800"
  defp severity_class("MEDIUM"), do: "bg-yellow-100 text-yellow-800"
  defp severity_class("LOW"), do: "bg-green-100 text-green-800"
  defp severity_class(_), do: "bg-gray-100 text-gray-800"

  defp empty_message(:vulnerabilities), do: "No vulnerabilities found"
  defp empty_message(:exposed_secrets), do: "No exposed secrets found"
  defp empty_message(:rbac_checks), do: "No RBAC issues found"
  defp empty_message(:config_audit_checks), do: "No configuration issues found"
  defp empty_message(:infra_checks), do: "No infrastructure issues found"
  defp empty_message(:sbom_components), do: "No components found"
  defp empty_message(_), do: "No items found"

  defp empty_description(:vulnerabilities),
    do: "This is a good thing! Your container images don't have any known vulnerabilities."

  defp empty_description(:exposed_secrets),
    do: "This is a good thing! Your container images don't contain any exposed secrets."

  defp empty_description(:rbac_checks),
    do: "This is a good thing! Your cluster RBAC configuration doesn't have any security issues."

  defp empty_description(:config_audit_checks),
    do: "This is a good thing! Your configuration doesn't have any security issues."

  defp empty_description(:infra_checks),
    do: "This is a good thing! Your infrastructure configuration doesn't have any security issues."

  defp empty_description(:sbom_components), do: "The SBOM (Software Bill of Materials) for this resource is empty."
  defp empty_description(_), do: "No additional information available."

  # Helper function to display component licenses
  defp component_licenses(assigns) do
    ~H"""
    <%= case @licenses do %>
      <% nil -> %>
        <span class="text-gray-400 text-sm">Unknown</span>
      <% [] -> %>
        <span class="text-gray-400 text-sm">Unknown</span>
      <% licenses when is_list(licenses) -> %>
        <div class="space-y-1">
          <%= for license <- licenses do %>
            <span class="inline-block px-2 py-1 text-xs font-medium rounded bg-blue-100 text-blue-800">
              {get_in(license, ~w(license name)) || "Unknown"}
            </span>
          <% end %>
        </div>
      <% _ -> %>
        <span class="text-gray-400 text-sm">Unknown</span>
    <% end %>
    """
  end
end
