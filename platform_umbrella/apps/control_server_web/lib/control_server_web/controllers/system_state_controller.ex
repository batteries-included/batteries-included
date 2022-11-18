defmodule ControlServerWeb.SystemStateController do
  use ControlServerWeb, :controller

  alias ControlServer.SystemState.Summarizer

  action_fallback(ControlServerWeb.FallbackController)

  def index(conn, _params) do
    render(conn, :index, summary: Summarizer.cached())
  end
end
