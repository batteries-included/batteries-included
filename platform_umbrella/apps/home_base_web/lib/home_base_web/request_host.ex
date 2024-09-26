defmodule HomeBaseWeb.RequestURL do
  @moduledoc false

  import CommonUI.UrlHelpers
  import Plug.Conn

  def assign_request_info(conn, _) do
    uri = get_uri_from_conn(conn)

    authority =
      if uri.port == 80 or uri.port == 443 do
        uri.host
      else
        "#{uri.host}:#{uri.port}"
      end

    conn
    |> put_session(:request_authority, authority)
    |> put_session(:request_scheme, uri.scheme)
  end

  def on_mount(:default, _params, %{"request_authority" => authority, "request_scheme" => scheme}, socket) do
    {:cont,
     socket
     |> Phoenix.Component.assign_new(:request_authority, fn -> authority end)
     |> Phoenix.Component.assign_new(:request_scheme, fn _ -> scheme end)}
  end
end
