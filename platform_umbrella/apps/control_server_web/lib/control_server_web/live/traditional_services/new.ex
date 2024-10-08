defmodule ControlServerWeb.Live.TraditionalServicesNew do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.TraditionalServices.Service
  alias ControlServerWeb.Live.TraditionalServices.FormComponent
  alias KubeServices.SystemState.SummaryBatteries

  def mount(params, _session, socket) do
    service = %Service{
      virtual_size: Atom.to_string(SummaryBatteries.default_size()),
      num_instances: 1
    }

    {:ok,
     socket
     |> assign(:current_page, :devtools)
     |> assign(:page_title, "New Traditional Service")
     |> assign(:project_id, params["project_id"])
     |> assign(:service, service)}
  end

  def render(assigns) do
    ~H"""
    <.live_component
      module={FormComponent}
      service={@service}
      id="service-form"
      action={:new}
      title={@page_title}
      project_id={@project_id}
    />
    """
  end
end
