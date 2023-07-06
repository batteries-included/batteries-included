defmodule WhatsUpWeb.SiteLive.Show do
  use WhatsUpWeb, :live_view

  alias WhatsUp.Detector

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:site, Detector.get_site!(id))}
  end

  defp page_title(:show), do: "Show Site"
  defp page_title(:edit), do: "Edit Site"

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.header>
      Site <%= @site.id %>
      <:subtitle>This is a site record from your database.</:subtitle>
      <:actions>
        <.link patch={~p"/sites/#{@site}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit site</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Url"><%= @site.url %></:item>
      <:item title="Timeout"><%= @site.timeout %></:item>
    </.list>

    <.back navigate={~p"/sites"}>Back to sites</.back>

    <.modal :if={@live_action == :edit} id="site-modal" show on_cancel={JS.patch(~p"/sites/#{@site}")}>
      <.live_component
        module={WhatsUpWeb.SiteLive.FormComponent}
        id={@site.id}
        title={@page_title}
        action={@live_action}
        site={@site}
        patch={~p"/sites/#{@site}"}
      />
    </.modal>
    """
  end
end
