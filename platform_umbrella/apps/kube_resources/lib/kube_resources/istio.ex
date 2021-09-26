defmodule KubeResources.IstioConfig do
  defmodule StringMatch do
    @derive Jason.Encoder
    defstruct [:exact, :prefix, :regex]

    def prefix(p), do: %__MODULE__{prefix: p}

    def value(%__MODULE__{} = sm), do: sm.exact || sm.prefix
  end

  defmodule HttpRewrite do
    @derive Jason.Encoder
    defstruct [:uri, :authority]
  end

  defmodule HttpMatchRequest do
    @derive Jason.Encoder
    defstruct [
      :name,
      :uri,
      :scheme,
      :method,
      :authority,
      :headers,
      :port,
      :sourceLabels,
      :gateways,
      :queryParams,
      :ignoreUriCase,
      :withoutHeaders,
      :sourceNamespace
    ]
  end

  defmodule HttpRouteDestination do
    @derive Jason.Encoder
    defstruct [:destination, :weight, :headers]

    def new(host), do: %__MODULE__{destination: %{host: host}}
  end

  defmodule HttpRoute do
    @derive Jason.Encoder
    defstruct [:rewrite, :name, match: [], route: []]

    def new(prefix, service_host, opts \\ []) do
      do_rewrite = Keyword.get(opts, :rewrite, False)

      maybe_rewite(
        %__MODULE__{
          name: name_from_prefix(prefix),
          match: [%HttpMatchRequest{uri: StringMatch.prefix(prefix)}],
          route: [HttpRouteDestination.new(service_host)]
        },
        do_rewrite
      )
    end

    defp maybe_rewite(%__MODULE__{} = route, True), do: add_rewrite(route)
    defp maybe_rewite(%__MODULE__{} = route, _), do: route

    def add_rewrite(%__MODULE__{} = route) do
      prefix = find_prefix(route)

      # We want to have /fooo and /fooo/ resolve as '/'
      # rather than '/' and '//' respectively.
      # This seems like something that istio doesn't like to do.
      # So we do this dance to match the more specific first
      route
      |> update_in(:rewrite, fn _ -> %HttpRewrite{uri: "/"} end)
      |> update_in(:match, fn l ->
        [%HttpMatchRequest{uri: StringMatch.exact(prefix <> "/")} | l]
      end)
    end

    defp name_from_prefix(prefix), do: String.replace(prefix, "/", "_")

    defp find_prefix(%__MODULE__{match: [head_match | _]}) do
      StringMatch.value(head_match.uri)
    end
  end

  defmodule VirtualService do
    @derive Jason.Encoder
    defstruct hosts: [], gateways: [], http: []

    def new(opts \\ []) do
      gateways = Keyword.get(opts, :gateways, ["battery-gateway"])
      hosts = Keyword.get(opts, :hosts, ["*"])
      routes = Keyword.get(opts, :routes, [])
      %__MODULE__{gateways: gateways, hosts: hosts, http: routes}
    end

    def prefix(prefix, service_host) do
      new(routes: [HttpRoute.new(prefix, service_host)])
    end

    def rewriting(prefix, service_host) do
      new(routes: [HttpRoute.new(prefix, service_host, reweite: True)])
    end
  end
end
