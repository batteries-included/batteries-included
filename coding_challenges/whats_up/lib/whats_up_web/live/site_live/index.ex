defmodule WhatsUpWeb.SiteLive.Index do
  use WhatsUpWeb, :live_view

  alias WhatsUp.Detector
  alias WhatsUp.Detector.Site

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :sites, Detector.list_sites())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Site")
    |> assign(:site, Detector.get_site!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Site")
    |> assign(:site, %Site{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Sites")
    |> assign(:site, nil)
  end

  @impl true
  def handle_info({WhatsUpWeb.SiteLive.FormComponent, {:saved, site}}, socket) do
    {:noreply, stream_insert(socket, :sites, site)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    site = Detector.get_site!(id)
    {:ok, _} = Detector.delete_site(site)

    {:noreply, stream_delete(socket, :sites, site)}
  end

  @impl true
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.header>
      Listing Sites
      <:actions>
        <.link patch={~p"/sites/new"}>
          <.button>New Site</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="sites"
      rows={@streams.sites}
      row_click={fn {_id, site} -> JS.navigate(~p"/sites/#{site}") end}
    >
      <:col :let={{_id, site}} label="Url"><%= site.url %></:col>
      <:col :let={{_id, site}} label="Timeout"><%= site.timeout %></:col>
      <:action :let={{_id, site}}>
        <div class="sr-only">
          <.link navigate={~p"/sites/#{site}"}>Show</.link>
        </div>
        <.link patch={~p"/sites/#{site}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, site}}>
        <.link
          phx-click={JS.push("delete", value: %{id: site.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="site-modal" show on_cancel={JS.patch(~p"/sites")}>
      <.live_component
        module={WhatsUpWeb.SiteLive.FormComponent}
        id={@site.id || :new}
        title={@page_title}
        action={@live_action}
        site={@site}
        patch={~p"/sites"}
      />
    </.modal>
    """
  end
end
