defmodule ControlServerWeb.Live.ContentAddressableIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ContentAddressable.DocumentsTable

  alias ControlServer.ContentAddressable

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign_stats(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {resources, meta}} <- ContentAddressable.list_documents(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:resources, resources)}
    end
  end

  defp assign_stats(socket) do
    %{oldest: oldest, record_count: cnt, newest: newest} = ContentAddressable.get_stats()

    socket
    |> assign(:count, cnt)
    |> assign(:oldest, oldest)
    |> assign(:newest, newest)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Content Addressable Storage" back_link={~p"/magic"}>
      <.flex>
        <.badge>
          <:item label="Resource Count">{@count}</:item>
          <:item label="Oldest">
            <.relative_display time={@oldest} />
          </:item>
        </.badge>
      </.flex>
    </.page_header>

    <.panel title="Resources">
      <.documents_table rows={@resources} meta={@meta} />
    </.panel>
    """
  end
end
