defmodule CommonUI.UrlHelpers do
  @moduledoc false
  import Plug.Conn

  def get_uri_from_conn(conn) do
    # request_url(conn) will always return http when running in cluster as TLS is terminated by istio / envoy
    # so set scheme if x-forwarded-proto is set or ssl is enabled
    conn
    |> req_url()
    |> scheme()
    |> fix_port()
    |> finalize_uri()
  end

  # start by getting the default request url
  defp req_url(conn), do: %{uri: conn |> request_url() |> URI.new!(), conn: conn}

  # determine the scheme to be using
  defp scheme(%{conn: conn, uri: uri} = accum) do
    conn
    |> get_req_header("x-forwarded-proto")
    |> List.first(uri.scheme)
    |> then(&Map.put(accum, :scheme, &1))
  end

  # no change
  defp fix_port(%{uri: %URI{} = uri, scheme: nil}), do: uri
  defp fix_port(%{uri: %URI{} = uri, scheme: ""}), do: uri
  defp fix_port(%{uri: %URI{scheme: old_scheme} = uri, scheme: new_scheme}) when old_scheme == new_scheme, do: uri

  # http -> https: change to 443
  defp fix_port(%{uri: %URI{scheme: "http", port: 80} = uri, scheme: "https"}),
    do: uri |> Map.put(:scheme, "https") |> Map.put(:port, 443)

  # leave port alone if switching from http -> https and we're not on the default port - 80
  defp fix_port(%{uri: %URI{scheme: "http"} = uri, scheme: "https"}), do: Map.put(uri, :scheme, "https")

  defp finalize_uri(uri), do: Map.put(uri, :path, "")
end
