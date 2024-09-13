defmodule HomeBaseWeb.Live.Admin.InstallationsIndex do
  @moduledoc false

  use HomeBaseWeb, :live_view

  import HomeBaseWeb.Admin.InstallationsTable

  alias HomeBase.CustomerInstalls

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Installations")}
  end

  def handle_params(_params, _session, socket) do
    {:noreply, assign(socket, :installations, CustomerInstalls.list_installations())}
  end

  def render(assigns) do
    ~H"""
    <.flex column>
      <.panel title="All Installations">
        <.installations_table rows={@installations} />
      </.panel>
    </.flex>
    """
  end
end
