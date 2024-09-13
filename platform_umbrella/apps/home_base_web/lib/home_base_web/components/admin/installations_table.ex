defmodule HomeBaseWeb.Admin.InstallationsTable do
  @moduledoc false

  use HomeBaseWeb, :html

  attr :rows, :list, default: []

  def installations_table(assigns) do
    ~H"""
    <.table
      id="installations-table"
      rows={@rows}
      row_click={&JS.navigate("/admin/installations/#{&1.id}")}
    >
      <:col :let={installation} label="ID"><%= installation.id %></:col>
      <:col :let={installation} label="Slug"><%= installation.slug %></:col>
      <:col :let={installation} label="Usage"><%= installation.usage %></:col>
      <:col :let={installation} label="Provider"><%= installation.kube_provider %></:col>
      <:col :let={installation} label="Default Size"><%= installation.default_size %></:col>

      <:action :let={installation}>
        <.button
          variant="minimal"
          link={~p"/admin/installations/#{installation}"}
          icon={:eye}
          id={"show_installation_" <> installation.id}
        />

        <.tooltip target_id={"show_installation_" <> installation.id}>
          Show Installation
        </.tooltip>
      </:action>
    </.table>
    """
  end
end
