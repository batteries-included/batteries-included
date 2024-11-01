defmodule CommonCore.Resources.VirtualServiceBuilder do
  @moduledoc false
  alias CommonCore.OpenAPI.IstioVirtualService.HTTPRoute
  alias CommonCore.OpenAPI.IstioVirtualService.L4MatchAttributes
  alias CommonCore.OpenAPI.IstioVirtualService.TCPRoute
  alias CommonCore.OpenAPI.IstioVirtualService.VirtualService

  @spec prefix(VirtualService.t(), String.t(), String.t(), non_neg_integer()) :: VirtualService.t()
  @doc """
  Adds a route to the given VirtualService that matches requests
  with the given prefix, and routes them to the provided service
  host and port.
  """
  def prefix(%VirtualService{} = virtual_service, prefix, service_host, service_port) do
    {:ok, route} =
      HTTPRoute.new(
        name: name_from_prefix(prefix),
        match: [%{uri: %{prefix: prefix}}],
        route: [%{destination: %{host: service_host, port: %{number: service_port}}}]
      )

    add_route(virtual_service, route)
  end

  @spec maybe_https_redirect(VirtualService.t(), boolean()) :: VirtualService.t()
  @doc """
  Adds a route to the given VirtualService that redirects http
  requests to https if SSL is enabled.

  Since we use cert_manager to provide certificates, we add the
  redirect here instead of at the gateway so that the cert_manager
  created ingress for HTTP01 verification will be more specific
  and not hit the redirect. Otherwise, the redirect applies to
  the verification request and it gets redirected and never validates.
  """
  def maybe_https_redirect(%VirtualService{} = virtual_service, false = _ssl_enabled?), do: virtual_service

  def maybe_https_redirect(%VirtualService{} = virtual_service, true = _ssl_enabled?) do
    {:ok, route} =
      HTTPRoute.new(
        name: "https-redirect",
        match: [%{uri: %{prefix: "/"}, scheme: %{exact: "http"}}],
        redirect: %{scheme: "https"}
      )

    prepend_route(virtual_service, route)
  end

  @spec rewriting(VirtualService.t(), String.t(), String.t(), non_neg_integer()) :: VirtualService.t()
  @doc """
  Adds a route to the given VirtualService that matches requests
  with the given prefix, and routes them to the provided service
  host and port.

  The route will also have the rewrite field set to remove the prefix so
  if the prefix is "/foo" then the received path will
  be "/" for "/foo" and "/foo/". For "/foo/bar" the received path will
  "/bar"
  """
  def rewriting(%VirtualService{} = virtual_service, prefix, service_host, service_port) do
    {:ok, route} =
      HTTPRoute.new(
        name: "rewriting:" <> name_from_prefix(prefix),

        # Add the rewrite field signaling to isito to remove the path prefix
        rewrite: %{uri: "/"},
        match: [
          # We want to have /fooo and /fooo/ resolve as '/'
          # rather than '/' and '//' respectively.
          # This seems like something that istio doesn't like to do.
          # So we do this dance to match the more specific first
          %{uri: %{prefix: prefix <> "/"}},
          %{uri: %{prefix: prefix}}
        ],
        route: [%{destination: %{host: service_host, port: %{number: service_port}}}]
      )

    add_route(virtual_service, route)
  end

  @spec fallback(VirtualService.t(), String.t(), non_neg_integer()) :: VirtualService.t()
  @doc """
  Adds a fallback route named "fallback" to the provided VirtualService.

   The fallback route will route all traffic that does not match any other route
   to the provided `service_host` and `service_port`.

  """
  def fallback(%VirtualService{} = virtual_service, service_host, service_port) do
    {:ok, route} =
      HTTPRoute.new(
        name: "fallback",
        route: [%{destination: %{host: service_host, port: %{number: service_port}}}]
      )

    add_route(virtual_service, route)
  end

  @spec tcp(VirtualService.t(), non_neg_integer(), String.t(), non_neg_integer()) :: VirtualService.t()
  @doc """
  Adds a TCP route to the given VirtualService that matches requests
  on the given `external_port` and routes them to the provided `service_host`
  and `service_port`.
  """
  def tcp(%VirtualService{} = virtual_service, external_port, service_host, service_port) do
    {:ok, route} =
      TCPRoute.new(
        match: [L4MatchAttributes.new!(port: external_port)],
        route: [%{destination: %{host: service_host, port: %{number: service_port}}}]
      )

    add_tcp(virtual_service, route)
  end

  defp prepend_route(%VirtualService{} = virtual_service, route) do
    update_in(virtual_service, [Access.key!(:http)], fn existing -> [route] ++ existing end)
  end

  defp add_route(%VirtualService{} = virtual_service, route) do
    update_in(virtual_service, [Access.key!(:http)], fn existing ->
      # Add the new route to the end of the list
      # so other prefixes take prefence.
      #
      # This lets the user add routes in priorty order
      existing ++ [route]
    end)
  end

  defp add_tcp(%VirtualService{} = virtual_service, tcp) do
    update_in(virtual_service, [Access.key!(:tcp)], fn existing -> [tcp | existing] end)
  end

  defp name_from_prefix(prefix), do: String.replace(prefix, "/", "_")
end
