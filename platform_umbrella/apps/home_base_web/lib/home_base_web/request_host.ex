defmodule HomeBaseWeb.RequestURL do
  @moduledoc false

  import Plug.Conn

  def assign_request_info(conn, _) do
    url =
      conn
      |> request_url()
      |> URI.new!()

    scheme =
      conn
      |> get_req_header("x-forwarded-proto")
      |> List.first(url.scheme)

    authority =
      if url.port == 80 or url.port == 443 do
        url.host
      else
        "#{url.host}:#{url.port}"
      end

    conn
    |> put_session(:request_authority, authority)
    |> put_session(:request_scheme, scheme)
  end

  def on_mount(:default, _params, %{"request_authority" => authority, "request_scheme" => scheme}, socket) do
    {:cont,
     socket
     |> Phoenix.Component.assign_new(:request_authority, fn -> authority end)
     |> Phoenix.Component.assign_new(:request_scheme, fn _ -> scheme end)}
  end
end
