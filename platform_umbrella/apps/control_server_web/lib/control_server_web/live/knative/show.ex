defmodule ControlServerWeb.Live.KnativeShow do
  @moduledoc """
  LiveView to display all the most relevant status of a Knative Service.

  This depends on the Knative operator being installed and
  the owned resources being present in kubernetes.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.KnativeDisplay

  alias EventCenter.KubeState, as: KubeEventCenter
  alias ControlServer.Knative
  alias KubeExt.KubeState
  alias KubeExt.OwnerLabel
  alias KubeExt.OwnerReference

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
    KubeState.get_all(:knative_service)
    |> Enum.filter(fn s -> service.id == OwnerLabel.get_owner(s) end)
    |> Enum.at(0, %{})
  end

  def k8_configuration(k8_service) do
    KubeState.get_all(:knative_configuration)
    |> Enum.filter(fn c -> KubeExt.uid(k8_service) == OwnerReference.get_owner(c) end)
    |> Enum.at(0, %{})
  end

  def k8_revisions(k8_configuration) do
    Enum.filter(
      KubeState.get_all(:knative_revision),
      fn r -> KubeExt.uid(k8_configuration) == OwnerReference.get_owner(r) end
    )
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = Knative.delete_service(socket.assigns.service)

    {:noreply, push_redirect(socket, to: ~p"/knative/services")}
  end

  defp page_title(:show), do: "Show Knative Service"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={:devtools} active={:knative_serving}>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
      <.service_display service={@k8_service} />
      <.revisions_display revisions={@k8_revisions} />
      <.h2>Actions</.h2>
      <.body_section>
        <.link navigate={~p"/knative/services/#{@service}/edit"}>
          <.button>
            Edit Service
          </.button>
        </.link>

        <.button phx-click="delete" data-confirm="Are you sure?">
          Delete Service
        </.button>
      </.body_section>
    </.layout>
    """
  end
end
