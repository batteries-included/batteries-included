defmodule ControlServerWeb.Live.IstioVirtualServicesIndex do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Istio.VirtualServicesTable

  alias KubeServices.KubeState

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_vitrual_services()
     |> assign_current_page()
     |> assign_page_title()}
  end

  defp assign_vitrual_services(socket) do
    assign(socket, virtual_services: KubeState.get_all(:istio_virtual_service))
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :net_sec)
  end

  defp assign_page_title(socket) do
    assign(socket, page_title: "Istio Virtual Services")
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/net_sec"} />

    <.panel title="Virtual Services">
      <.virtual_services_table abbridged rows={@virtual_services} />
    </.panel>
    """
  end
end
