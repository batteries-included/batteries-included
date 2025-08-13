defmodule ControlServerWeb.TrivyReports.ExposedSecretsTable do
  @moduledoc false
  use ControlServerWeb, :html

  def exposed_secrets_table(assigns) do
    ~H"""
    <%= if @rows && length(@rows) > 0 do %>
      <.table id="exposed-secrets-table" rows={@rows}>
        <:col :let={secret} label="Severity">{get_in(secret, ~w(severity))}</:col>
        <:col :let={secret} label="Title">
          <.truncate_tooltip value={get_in(secret, ~w(title))} />
        </:col>
        <:col :let={secret} label="Rule ID">{get_in(secret, ~w(ruleID))}</:col>
        <:col :let={secret} label="Category">{get_in(secret, ~w(category))}</:col>
        <:col :let={secret} label="Match">
          <.truncate_tooltip value={get_in(secret, ~w(match))} />
        </:col>
      </.table>
    <% else %>
      <div class="text-center text-gray-500 py-8">
        <div class="text-xl">
          No exposed secrets found
        </div>
        <div class="text-sm mt-2">
          This is a good thing! Your container images don't contain any exposed secrets.
        </div>
      </div>
    <% end %>
    """
  end
end
