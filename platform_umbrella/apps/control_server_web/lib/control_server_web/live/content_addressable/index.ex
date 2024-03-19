defmodule ControlServerWeb.Live.ContentAddressableIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ContentAddressable.ResourceTable

  alias ControlServer.ContentAddressable

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title="Content Addressable Storage" back_link={~p"/magic"}>
      <:menu>
        <.flex>
          <.badge>
            <:item label="Resource Count"><%= @count %></:item>
            <:item label="Oldest">
              <.relative_display time={@oldest} />
            </:item>
          </.badge>
        </.flex>
      </:menu>
    </.page_header>

    <.panel title="Resources">
      <.documents_table resources={elem(@resources, 0)} />
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_stats() |> assign_resources()}
  end

  defp assign_stats(socket) do
    %{oldest: oldest, record_count: cnt, newest: newest} = ContentAddressable.get_stats()

    socket
    |> assign(:count, cnt)
    |> assign(:oldest, oldest)
    |> assign(:newest, newest)
  end

  defp assign_resources(socket) do
    assign(socket, :resources, ContentAddressable.paginated_documents())
  end
end
