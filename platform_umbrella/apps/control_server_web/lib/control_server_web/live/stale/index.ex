defmodule ControlServerWeb.Live.StaleIndex do
  use ControlServerWeb, {:live_view, layout: :fresh}

  import K8s.Resource.FieldAccessors

  alias KubeServices.Stale
  alias CommonCore.ApiVersionKind
  alias Phoenix.Naming
  alias KubeServices.ResourceDeleter

  require Logger

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1><%= @page_title %></.h1>
    <.stale_table :if={@stale != nil && @stale != []} rows={@stale} />
    <.empty_state :if={@stale == nil || @stale == []} />
    """
  end

  defp stale_table(assigns) do
    ~H"""
    <.table id="stale-table" rows={@rows}>
      <:col :let={resource} label="Kind">
        <%= Naming.humanize(ApiVersionKind.resource_type!(resource)) %>
      </:col>
      <:col :let={resource} label="Name">
        <%= name(resource) %>
      </:col>
      <:col :let={resource} label="Namespace">
        <%= namespace(resource) %>
      </:col>

      <:action :let={resource}>
        <.a
          phx-click="delete"
          phx-value-kind={ApiVersionKind.resource_type!(resource)}
          phx-value-name={name(resource)}
          phx-value-namespace={namespace(resource)}
          data-confirm="Are you sure?"
          variant="styled"
        >
          Delete Now
        </.a>
      </:action>
    </.table>
    """
  end

  defp empty_state(assigns) do
    ~H"""
    <.card>
      <:title>Empty Queue</:title>
      <div class="max-w-none prose prose-lg my-4">
        <p>
          There are currently no Kubernetes resources that are stale (no longer referenced in a deploy). Batteries Included control server will continue to monitor and seach for resources to clean up. Any Kubernetes objects found that are not needed will be placed in this queue for eventual deletion.
        </p>
      </div>
      <img class="w-auto max-w-md mx-auto" src={~p"/images/search-amico.svg"} alt="" />
    </.card>
    """
  end

  @impl Phoenix.LiveView
  def handle_event(
        "delete",
        %{"kind" => kind, "name" => name, "namespace" => namespace} = _params,
        socket
      ) do
    with %{} = res <-
           get_resource(socket.assigns.stale, String.to_existing_atom(kind), name, namespace),
         {:ok, deleted_resource} <- ResourceDeleter.delete(res) do
      Logger.debug("Deleted and got back #{inspect(deleted_resource)}")
      Process.sleep(500)
      {:noreply, assign_stale(socket, fetch_stale())}
    else
      e ->
        Logger.debug("Error, #{inspect(e)}")
        {:noreply, socket}
    end
  end

  defp get_resource(stale_list, wanted_kind, wanted_name, wanted_namespace) do
    Enum.find(stale_list, nil, fn r ->
      ApiVersionKind.resource_type!(r) == wanted_kind && name(r) == wanted_name &&
        namespace(r) == wanted_namespace
    end)
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign_stale(fetch_stale())
     |> assign_page_title("Stale Deleter Queue")}
  end

  def assign_stale(socket, stale) do
    assign(socket, stale: stale)
  end

  def assign_page_title(socket, page_title) do
    assign(socket, page_title: page_title)
  end

  defp fetch_stale, do: Stale.find_potential_stale()
end
