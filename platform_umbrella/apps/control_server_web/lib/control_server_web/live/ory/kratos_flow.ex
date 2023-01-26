defmodule ControlServerWeb.Live.OryKratosFlow do
  use ControlServerWeb, :live_view

  import CommonUI.Icons.Batteries
  import KubeServices.SystemState.SummaryHosts
  import ControlServerWeb.Loader
  import ControlServerWeb.Ory.Flow

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen">
      <div class="flex flex-1 flex-col justify-center py-12 px-4 sm:px-6 lg:flex-none lg:px-20 xl:px-24">
        <div class="mx-auto w-full max-w-sm lg:w-96">
          <div>
            <.batteries_logo class="h-12 w-auto mx-auto mb-4" />
            <.h2>
              <%= @page_title %>
            </.h2>
          </div>

          <div class="mt-8">
            <.flow_container flow_url={@flow_url} flow_id={@flow_id}>
              <.loader :if={@flow_payload == nil} />
              <%= if @flow_payload != nil do %>
                <.flow_form ui={Map.get(@flow_payload, "ui", %{})} />
              <% end %>
            </.flow_container>
          </div>
        </div>
      </div>
      <div class="relative hidden w-0 flex-1 lg:block">
        <img class="absolute inset-0 h-full w-full object-cover" src={@background_image} />
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign_flow_id(nil)
     |> assign_flow_payload(nil)
     |> assign_flow_url("")
     |> assign_page_title(page_title(socket.assigns.live_action))
     |> assign_background_image(background_image(socket.assigns.live_action))
     |> assign_browser_url(browser_url(socket.assigns.live_action))}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"flow" => flow_id} = _params, _uri, socket) do
    {:noreply,
     socket
     |> assign_flow_id(flow_id)
     |> assign_flow_url(flow_url(socket.assigns.live_action, flow_id))}
  end

  @impl Phoenix.LiveView
  def handle_params(%{} = _params, _uri, socket) do
    {:noreply, redirect(socket, external: socket.assigns.browser_url)}
  end

  @impl Phoenix.LiveView
  def handle_event("kratos:loaded", %{} = flow, socket) do
    {:noreply, assign_flow_payload(socket, flow)}
  end

  def assign_flow_id(socket, flow_id) do
    assign(socket, flow_id: flow_id)
  end

  def assign_flow_payload(socket, flow_payload) do
    assign(socket, flow_payload: flow_payload)
  end

  def assign_browser_url(socket, browser_url) do
    assign(socket, browser_url: browser_url)
  end

  def assign_flow_url(socket, flow_url) do
    assign(socket, flow_url: flow_url)
  end

  def assign_background_image(socket, background_image) do
    assign(socket, background_image: background_image)
  end

  def assign_page_title(socket, page_title) do
    assign(socket, page_title: page_title)
  end

  def page_title(:login), do: "Sign in to your account"
  def page_title(:registration), do: "Register an account"
  def page_title(:recovery), do: "Recover your account"
  def page_title(:verification), do: "Verify your Email/Phone"
  def page_title(_page_type), do: "Control Server"

  def flow_url(page_type, flow_id)

  def flow_url(page_type, flow_id) when is_atom(page_type),
    do: "http://#{kratos_host()}/self-service/#{to_string(page_type)}/flows?id=#{flow_id}"

  def browser_url(page_type)
  def browser_url(:login), do: "http://#{kratos_host()}/self-service/login/browser"
  def browser_url(:recovery), do: "http://#{kratos_host()}/self-service/recovery/browser"
  def browser_url(:verification), do: "http://#{kratos_host()}/self-service/verification/browser"
  def browser_url(:registration), do: "http://#{kratos_host()}/self-service/registration/browser"

  def background_image(:login), do: "/images/junior-ferreira-7esRPTt38nI-unsplash.jpg"
  def background_image(:recovery), do: "/images/jamie-street-_94HLr_QXo8-unsplash.jpg"
  def background_image(:verification), do: "/images/rob-wicks-wmTmWDuvQUg-unsplash.jpg"
  def background_image(:registration), do: "/images/nasa-JkaKy_77wF8-unsplash.jpg"

  def background_image(_), do: "/images/junior-ferreira-7esRPTt38nI-unsplash.jpg"
end
