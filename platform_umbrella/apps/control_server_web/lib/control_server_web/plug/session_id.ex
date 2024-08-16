defmodule ControlServerWeb.Plug.SessionID do
  @moduledoc false
  import Plug.Conn

  def init(opts \\ []) do
    opts
  end

  def call(conn, _opts) do
    maybe_require_session_id(conn)
  end

  defp maybe_require_session_id(conn) do
    # If there's a user let them in
    if get_session_id(conn) == nil do
      put_session(conn, :session_id, CommonCore.Ecto.BatteryUUID.autogenerate())
    else
      conn
    end
  end

  def get_session_id(conn) do
    get_session(conn, :session_id)
  end
end
