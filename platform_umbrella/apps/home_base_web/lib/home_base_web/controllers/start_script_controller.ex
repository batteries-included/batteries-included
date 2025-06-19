defmodule HomeBaseWeb.StartScriptController do
  use HomeBaseWeb, :controller

  action_fallback HomeBaseWeb.FallbackController

  def install_bi(conn, _params) do
    conn
    |> put_status(:ok)
    |> text(HomeBase.Scripts.install_bi())
  end

  def start_local(conn, _params) do
    conn
    |> put_status(:ok)
    |> text(HomeBase.Scripts.start_local())
  end
end
