defmodule ControlServerWeb.TrivyReports.SBOMTable do
  @moduledoc false
  use ControlServerWeb, :html

  def sbom_table(assigns) do
    ~H"""
    <%= if @rows && length(@rows) > 0 do %>
      <.table id="sbom-table" rows={@rows}>
        <:col :let={component} label="Name">{get_in(component, ~w(name))}</:col>
        <:col :let={component} label="Version">{get_in(component, ~w(version))}</:col>
        <:col :let={component} label="Type">{get_in(component, ~w(type))}</:col>
        <:col :let={component} label="Licenses">
          <%= if get_in(component, ~w(licenses)) do %>
            <%= for license <- get_in(component, ~w(licenses)) do %>
              <span class="inline-block bg-gray-100 rounded px-2 py-1 text-xs mr-1 mb-1">
                {get_in(license, ~w(license name))}
              </span>
            <% end %>
          <% else %>
            <span class="text-gray-400">None</span>
          <% end %>
        </:col>
        <:col :let={component} label="Supplier">
          {get_in(component, ~w(supplier name)) || "Unknown"}
        </:col>
      </.table>
    <% else %>
      <div class="text-center text-gray-500 py-8">
        <div class="text-xl">
          No SBOM components found
        </div>
      </div>
    <% end %>
    """
  end
end
