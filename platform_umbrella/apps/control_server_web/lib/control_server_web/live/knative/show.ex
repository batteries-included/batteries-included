defmodule ControlServerWeb.Live.KnativeShow do
  @moduledoc """
  LiveView to display all the most relevant status of a Knative Service.

  This depends on the Knative operator being installed and
  the owned resources being present in kubernetes.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import CommonUI.DatetimeDisplay
  import ControlServerWeb.KnativeDisplay

  alias CommonCore.Resources.OwnerReference
  alias ControlServer.Knative
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeEventCenter.subscribe(:pod)
    :ok = KubeEventCenter.subscribe(:knative_service)
    :ok = KubeEventCenter.subscribe(:knative_revision)
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    service = Knative.get_service!(id)

    {:noreply,
     socket
     |> assign(:id, id)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:service, service)
     |> assign_k8s(service)}
  end

  defp assign_k8s(socket, service) do
    k8_service = k8_service(service)
    k8_configuration = k8_configuration(k8_service)

    socket
    |> assign(:k8_service, k8_service)
    |> assign(:k8_configuration, k8_configuration)
    |> assign(:k8_revisions, k8_revisions(k8_configuration))
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, assign_k8s(socket, socket.assigns.service)}
  end

  def k8_service(service) do
    :knative_service
    |> KubeState.get_all()
    |> Enum.filter(fn s -> service.id == labeled_owner(s) end)
    |> Enum.at(0, %{})
  end

  def k8_configuration(k8_service) do
    :knative_configuration
    |> KubeState.get_all()
    |> Enum.filter(fn c -> uid(k8_service) == OwnerReference.get_owner(c) end)
    |> Enum.at(0, %{})
  end

  def k8_revisions(k8_configuration) do
    Enum.filter(
      KubeState.get_all(:knative_revision),
      fn r -> uid(k8_configuration) == OwnerReference.get_owner(r) end
    )
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = Knative.delete_service(socket.assigns.service)

    {:noreply, push_redirect(socket, to: ~p"/knative/services")}
  end

  defp page_title(:show), do: "Show Knative Service"

  defp edit_url(service), do: ~p"/knative/services/#{service}/edit"

  defp service_url(service) do
    get_in(service, ~w(status url))
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header
      title={@page_title}
      back_button={%{link_type: "live_redirect", to: ~p"/knative/services"}}
    >
      <:menu>
        <.flex>
          <.button>Edit History</.button>

          <.flex>
            <PC.icon_button to={edit_url(@service)} link_type="live_redirect">
              <Heroicons.pencil solid />
            </PC.icon_button>

            <PC.icon_button type="button" phx-click="delete" data-confirm="Are you sure?">
              <Heroicons.trash />
            </PC.icon_button>
          </.flex>
        </.flex>
      </:menu>
    </.page_header>

    <.flex class="flex-col">
      <.flex>
        <.data_horizontal_bordered>
          <:item title="Name">
            <%= @service.name %>
          </:item>
          <:item title="Namespace"><%= namespace(@k8_service) %></:item>
          <:item title="Started">
            <.relative_display time={creation_timestamp(@k8_service)} />
          </:item>
          <:item title="Url">
            <.a href={service_url(@k8_service)} variant="external">
              <%= service_url(@k8_service) %>
            </.a>
          </:item>
        </.data_horizontal_bordered>
      </.flex>

      <.service_display service={@k8_service} revisions={@k8_revisions} />
    </.flex>
    """
  end
end
