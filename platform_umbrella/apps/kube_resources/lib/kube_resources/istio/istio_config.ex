defmodule KubeResources.IstioConfig do
  defmodule StringMatch do
    defstruct [:exact, :prefix, :regex]

    def prefix(p), do: %__MODULE__{prefix: p}
    def exact(p), do: %__MODULE__{exact: p}

    def value(%__MODULE__{} = sm), do: sm.exact || sm.prefix
  end

  defmodule Destination do
    defstruct [:host, :subset, :port]
  end

  defmodule HttpRewrite do
    defstruct [:uri, :authority]
  end

  defmodule HttpMatchRequest do
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

  defmodule RouteDestination do
    defstruct [:destination, :weight]

    def new(host), do: %__MODULE__{destination: %Destination{host: host}}

    def new(port, host),
      do: %__MODULE__{destination: %Destination{host: host, port: %{number: port}}}
  end

  defmodule HttpRouteDestination do
    defstruct [:destination, :weight, :headers]

    def new(host), do: %__MODULE__{destination: %Destination{host: host}}
    def new(host, nil = _port), do: %__MODULE__{destination: %Destination{host: host}}

    def new(host, port),
      do: %__MODULE__{destination: %Destination{host: host, port: %{number: port}}}
  end

  defmodule HttpRoute do
    defstruct [:rewrite, :name, :fault, match: [], route: []]

    def prefix(prefix, service_host, opts \\ []) do
      do_rewrite = Keyword.get(opts, :rewrite, False)
      port = Keyword.get(opts, :port, nil)

      maybe_rewite(
        %__MODULE__{
          name: name_from_prefix(prefix),
          match: [%HttpMatchRequest{uri: StringMatch.prefix(prefix)}],
          route: [HttpRouteDestination.new(service_host, port)]
        },
        do_rewrite
      )
    end

    def fallback(service_host, opts \\ []) do
      name = Keyword.get(opts, :name, "fallback")

      %__MODULE__{
        name: name,
        route: [HttpRouteDestination.new(service_host)]
      }
    end

    def fault(opts \\ []) do
      name = Keyword.get(opts, :name, "fault")

      %__MODULE__{
        name: name,
        fault: %{abort: %{httpStatus: 404}}
      }
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
      |> Map.put(:rewrite, %HttpRewrite{uri: "/"})
      |> Map.update(:match, [], fn l ->
        [%HttpMatchRequest{uri: StringMatch.prefix(prefix <> "/")} | l]
      end)
    end

    defp name_from_prefix(prefix), do: String.replace(prefix, "/", "_")

    defp find_prefix(%__MODULE__{match: [head_match | _]}) do
      StringMatch.value(head_match.uri)
    end
  end

  defmodule L4MatchAttributes do
    defstruct [:port, :gateways]

    def port(port) do
      %__MODULE__{port: port}
    end
  end

  defmodule TCPRoute do
    defstruct match: [], route: []

    def port(port, service_port, service_host) do
      %__MODULE__{
        match: [L4MatchAttributes.port(port)],
        route: [RouteDestination.new(service_port, service_host)]
      }
    end
  end

  defmodule VirtualService do
    defstruct hosts: [], gateways: [], http: [], tcp: []

    def new(opts \\ []) do
      gateways = Keyword.get(opts, :gateways, ["battery-istio/ingressgateway"])
      hosts = Keyword.get(opts, :hosts, ["*"])
      routes = Keyword.get(opts, :http, [])
      tcp = Keyword.get(opts, :tcp, [])
      %__MODULE__{gateways: gateways, hosts: hosts, http: routes, tcp: tcp}
    end

    def prefix(prefix, service_host, opts \\ []) do
      {route_keywords, rest} = Keyword.split(opts, [:port])

      rest
      |> Keyword.merge(http: [HttpRoute.prefix(prefix, service_host, route_keywords)])
      |> new()
    end

    def tcp_port(port, service_port, service_host, opts \\ []) do
      opts
      |> Keyword.merge(tcp: [TCPRoute.port(port, service_port, service_host)])
      |> new()
    end

    def rewriting(prefix, service_host, opts \\ []) do
      opts
      |> Keyword.merge(http: [HttpRoute.prefix(prefix, service_host, rewrite: True)])
      |> new()
    end

    def fallback(service_host, opts \\ []) do
      opts
      |> Keyword.merge(http: [HttpRoute.fallback(service_host)])
      |> new()
    end
  end

  defimpl Jason.Encoder,
    for: [
      VirtualService,
      TCPRoute,
      L4MatchAttributes,
      HttpRoute,
      HttpRouteDestination,
      RouteDestination,
      HttpMatchRequest,
      HttpRewrite,
      Destination,
      StringMatch
    ] do
    def encode(value, opts) do
      value
      |> Map.from_struct()
      |> Map.reject(fn
        {_k, nil} -> true
        {_k, _} -> false
      end)
      |> Jason.Encode.map(opts)
    end
  end
end
