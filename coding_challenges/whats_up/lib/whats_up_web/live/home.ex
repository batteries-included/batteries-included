defmodule WhatsUpWeb.HomeLive.Home do
  use WhatsUpWeb, :live_view

  @impl Phoenix.LiveView
  @spec mount(any, any, map) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    Process.send_after(self(), :update, 750)
    {:ok, assign(socket, :loaded, false)}
  end

  @impl Phoenix.LiveView
  @spec handle_info(:update, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info(:update, socket) do
    Process.send_after(self(), :update, 10_000)

    {:noreply, assign_sites(socket)}
  end

  defp assign_sites(socket) do
    %{up: up, down: down} = WhatsUp.status()

    socket
    |> assign(:loaded, true)
    |> assign(:up, up)
    |> assign(:down, down)
  end

  @impl Phoenix.LiveView
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div :if={@loaded}>
      <.header>
        Up
      </.header>
      <.table id="sites_up" rows={@up}>
        <:col :let={site} label="Url"><.link href={site.url}><%= site.url %></.link></:col>
      </.table>

      <.header>
        Down
      </.header>
      <.table id="sites_down" rows={@down}>
        <:col :let={site} label="Url"><.link href={site.url}><%= site.url %></.link></:col>
      </.table>
    </div>

    <div :if={@loaded == false} class="text-pink-500 flex justify-center">
      <div class="text-4xl">
        Loading
      </div>
    </div>
    """
  end
end
