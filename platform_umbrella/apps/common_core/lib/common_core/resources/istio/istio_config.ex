defmodule CommonCore.Resources.IstioConfig do
  use TypedStruct

  typedstruct module: PortSelector do
    field :number, integer()
  end

  defmodule StringMatch do
    typedstruct do
      field :exact, String.t(), enforce: false
      field :prefix, PortSelector.t(), enforce: false
      field :regext, PortSelector.t(), enforce: false
    end

    def prefix(p), do: %__MODULE__{prefix: p}
    def exact(p), do: %__MODULE__{exact: p}

    def value(%__MODULE__{} = sm), do: sm.exact || sm.prefix
  end

  typedstruct module: Destination do
    field :host, String.t()
    field :subset, String.t(), enforce: false
    field :port, PortSelector.t(), enforce: false
  end

  typedstruct module: HttpRewrite do
    field :uri, String.t(), enforce: false
    field :authority, PortSelector.t(), enforce: false
  end

  typedstruct module: Percent do
    field :value, float(), enforce: false
  end

  typedstruct module: Delay do
    field :fixedDelay, map(), enforce: false
    field :percentage, Percent.t(), enforce: false
    field :percent, integer(), enforce: false
  end

  typedstruct module: Abort do
    field :httpStatus, integer(), enforce: false
    field :grpcStatus, String.t(), enforce: false
    field :percentage, Percent.t(), enforce: false
  end

  typedstruct module: HttpFaultInjection do
    field :delay, Delay.t(), enforce: false
    field :abort, Abort.t(), enforce: false
  end

  typedstruct module: HttpMatchRequest do
    field :name, String.t(), enforce: false
    field :uri, StringMatch.t(), enforce: false
    field :scheme, StringMatch.t(), enforce: false
    field :method, StringMatch.t(), enforce: false
    field :authority, StringMatch.t(), enforce: false
    field :headers, map(), enforce: false
    field :port, integer(), enfore: false
    field :sourceLabels, map(), enforce: false
    field :gateways, list(String.t()), enforce: false
    field :queryParams, map(), enforce: false
    field :ignoreUriCase, bool(), enforce: false
    field :withoutHeaders, map(), enforce: false
    field :sourceNamespace, String.t(), enforce: false
    field :statPrefix, String.t(), enforce: false
  end

  typedstruct module: HeaderOperations do
    field :set, map(), enforce: false
    field :add, map(), enforce: false
    field :remove, list(String.t()), enforce: false
  end

  typedstruct module: Headers do
    field :request, HeaderOperations.t(), enforce: false
    field :response, HeaderOperations.t(), enforce: false
  end

  defmodule RouteDestination do
    typedstruct do
      field :destination, Destination.t(), enforce: false
      field :weight, integer(), enforce: false
    end

    def new(host), do: %__MODULE__{destination: %Destination{host: host}}

    def new(port, host),
      do: %__MODULE__{destination: %Destination{host: host, port: %PortSelector{number: port}}}
  end

  defmodule HttpRouteDestination do
    typedstruct do
      field :destination, Destination.t(), enforce: false
      field :weight, integer(), enforce: false
      field :headers, Headers.t(), enforce: false
    end

    def new(host), do: %__MODULE__{destination: %Destination{host: host}}
    def new(host, nil = _port), do: %__MODULE__{destination: %Destination{host: host}}

    def new(host, port),
      do: %__MODULE__{destination: %Destination{host: host, port: %PortSelector{number: port}}}
  end

  defmodule HttpRoute do
    typedstruct do
      field :name, String.t(), enforce: false
      field :match, list(HttpMatchRequest.t()), enforce: false
      field :route, list(HttpRouteDestination.t()), enforce: false
      field :rewrite, HttpRewrite.t(), enforce: false
      field :fault, HttpFaultInjection.t(), enforce: false
      field :headers, Headers.t(), enforce: false
    end

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
      port = Keyword.get(opts, :port, nil)

      %__MODULE__{
        name: name,
        route: [HttpRouteDestination.new(service_host, port)]
      }
    end

    def fault(opts \\ []) do
      name = Keyword.get(opts, :name, "fault")

      %__MODULE__{
        name: name,
        fault: %HttpFaultInjection{abort: %{httpStatus: 404}}
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
      gateways = Keyword.get(opts, :gateways, ["battery-istio/ingress"])
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

    def fallback_port(service_host, service_port, opts \\ []) do
      opts
      |> Keyword.merge(http: [HttpRoute.fallback(service_host, port: service_port)])
      |> new()
    end
  end

  defimpl Jason.Encoder,
    for: [
      Abort,
      Delay,
      Destination,
      HeaderOperations,
      Headers,
      HttpFaultInjection,
      HttpMatchRequest,
      HttpRewrite,
      HttpRoute,
      HttpRouteDestination,
      L4MatchAttributes,
      Percent,
      PortSelector,
      RouteDestination,
      StringMatch,
      TCPRoute,
      VirtualService
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
