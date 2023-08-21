defmodule ControlServerWeb.Live.ContentAddressableIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  import CommonUI.Stats
  import ControlServerWeb.ContentAddressable.ResourceTable

  alias ControlServer.ContentAddressable

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1>Content Addressable Storage</.h1>
    <.stats>
      <.stat>
        <.stat_title>Resource Count</.stat_title>
        <.stat_description>The number stored resources</.stat_description>
        <.stat_value><%= @count %></.stat_value>
      </.stat>
      <.stat>
        <.stat_title>Oldest</.stat_title>
        <.stat_description>The most well seasoned</.stat_description>
        <.stat_value>
          <%= Timex.format!(@oldest, "{RFC822z}") %>
        </.stat_value>
      </.stat>
      <.stat>
        <.stat_title>Newest</.stat_title>
        <.stat_description>The freshest</.stat_description>
        <.stat_value>
          <%= Timex.format!(@newest, "{RFC822z}") %>
        </.stat_value>
      </.stat>
    </.stats>

    <.documents_table resources={elem(@resources, 0)} />
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
