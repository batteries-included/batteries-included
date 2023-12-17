defmodule ControlServerWeb.Live.FerretServiceShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import CommonUI.DatetimeDisplay
  import ControlServerWeb.PodsTable

  alias ControlServer.FerretDB
  alias KubeServices.KubeState

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign_page_title(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    service = FerretDB.get_ferret_service!(id)

    {:noreply,
     socket
     |> assign_page_title()
     |> assign_ferret_service(service)
     |> assign_pods()}
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: "Show Ferret Service", current_page: :data)
  end

  defp assign_pods(%{assigns: %{ferret_service: ferret_service}} = socket) do
    pods =
      :pod
      |> KubeState.get_all()
      |> Enum.filter(fn pod -> ferret_service.id == labeled_owner(pod) end)

    assign(socket, pods: pods)
  end

  defp assign_ferret_service(socket, ferret_service) do
    assign(socket, ferret_service: ferret_service)
  end

  defp edit_url(ferret_service), do: ~p"/ferretdb/#{ferret_service}/edit"
  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header
      title={"FerretDB Service: #{@ferret_service.name}"}
      back_button={%{link_type: "live_redirect", to: ~p"/ferretdb"}}
    >
      <:menu>
        <.flex>
          <.data_horizontal_bordered>
            <:item title="Instances"><%= @ferret_service.instances %></:item>
            <:item title="Started">
              <.relative_display time={@ferret_service.inserted_at} />
            </:item>
          </.data_horizontal_bordered>

          <.button>Edit History</.button>

          <.flex gaps="0">
            <PC.icon_button to={edit_url(@ferret_service)} link_type="live_redirect">
              <Heroicons.pencil solid />
            </PC.icon_button>

            <PC.icon_button type="button" phx-click="delete" data-confirm="Are you sure?">
              <Heroicons.trash />
            </PC.icon_button>
          </.flex>
        </.flex>
      </:menu>
    </.page_header>

    <.panel title="Pods">
      <.pods_table pods={@pods} />
    </.panel>
    """
  end
end
