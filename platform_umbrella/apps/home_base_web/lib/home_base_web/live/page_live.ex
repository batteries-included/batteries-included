defmodule HomeBaseWeb.PageLive do
  @moduledoc false
  use HomeBaseWeb, {:live_view, "centered.html"}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       query: "",
       results: %{}
     )}
  end
end
