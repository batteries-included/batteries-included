defmodule CommonCore.OpenAPI.IstioVirtualService do
  @moduledoc false

  defmodule Delegate do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :name, :string
      field :namespace, :string
    end
  end

  defmodule StringMatch do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :exact, :string
      field :prefix, :string
      field :regex, :string
    end
  end

  defmodule HTTPBody do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :bytes, :string
      field :string, :string
    end
  end

  defmodule HTTPDirectResponse do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_one :body, HTTPBody
      field :status, :integer
    end
  end

  defmodule HTTPRedirect do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :authority, :string
      field :redirectCode, :integer
      field :scheme, :string
      field :uri, :string
    end
  end

  defmodule HTTPRetry do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :attempts, :integer
      field :perTryTimeout, :string
      field :retryOn, :string
      field :retryRemoteLocalities, :boolean
    end
  end

  defmodule Headers.HeaderOperations do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :add, :map
      field :remove, {:array, :string}
      field :set, :map
    end
  end

  defmodule Headers do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_one :request, Headers.HeaderOperations
      embeds_one :response, Headers.HeaderOperations
    end
  end

  defmodule L4MatchAttributes do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :destinationSubnets, {:array, :string}
      field :gateways, {:array, :string}
      field :port, :integer
      field :sourceLabels, :map
      field :sourceNamespace, :string
      field :sourceSubnet, :string
    end
  end

  defmodule Percent do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :value, :float
    end
  end

  defmodule HTTPFaultInjection.Abort do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_one :percentage, Percent
    end
  end

  defmodule HTTPFaultInjection.Delay do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :percent, :integer
      embeds_one :percentage, Percent
    end
  end

  defmodule HTTPFaultInjection do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_one :abort, HTTPFaultInjection.Abort
      embeds_one :delay, HTTPFaultInjection.Delay
    end
  end

  defmodule PortSelector do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :number, :integer
    end
  end

  defmodule Destination do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :host, :string
      embeds_one :port, PortSelector
      field :subset, :string
    end
  end

  defmodule HTTPMirrorPolicy do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_one :destination, Destination
      embeds_one :percentage, Percent
    end
  end

  defmodule HTTPRouteDestination do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_one :destination, Destination
      embeds_one :headers, Headers
      field :weight, :integer
    end
  end

  defmodule RegexRewrite do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :match, :string
      field :rewrite, :string
    end
  end

  defmodule HTTPRewrite do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :authority, :string
      field :uri, :string
      embeds_one :uriRegexRewrite, RegexRewrite
    end
  end

  defmodule RouteDestination do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_one :destination, Destination
      field :weight, :integer
    end
  end

  nil

  defmodule CorsPolicy do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :allowCredentials, :boolean
      field :allowHeaders, {:array, :string}
      field :allowMethods, {:array, :string}
      field :allowOrigin, {:array, :string}
      embeds_many :allowOrigins, StringMatch
      field :exposeHeaders, {:array, :string}
      field :maxAge, :string
    end
  end

  defmodule HTTPMatchRequest do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_one :authority, StringMatch
      field :gateways, {:array, :string}
      field :headers, :map
      field :ignoreUriCase, :boolean
      embeds_one :method, StringMatch
      field :name, :string
      field :port, :integer
      field :queryParams, :map
      embeds_one :scheme, StringMatch
      field :sourceLabels, :map
      field :sourceNamespace, :string
      field :statPrefix, :string
      embeds_one :uri, StringMatch
      field :withoutHeaders, :map
    end
  end

  defmodule HTTPRoute do
    #
    #
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_one :corsPolicy, CorsPolicy
      embeds_one :delegate, Delegate
      embeds_one :directResponse, HTTPDirectResponse
      embeds_one :fault, HTTPFaultInjection
      embeds_one :headers, Headers
      embeds_many :match, HTTPMatchRequest
      embeds_one :mirror, Destination
      field :mirrorPercent, :integer
      embeds_one :mirrorPercentage, Percent
      # TODO: Figure out versioning on this field
      #
      # embeds_many :mirrors, HTTPMirrorPolicy
      field :name, :string
      embeds_one :redirect, HTTPRedirect
      embeds_one :retries, HTTPRetry
      embeds_one :rewrite, HTTPRewrite
      embeds_many :route, HTTPRouteDestination
      field :timeout, :string
    end
  end

  defmodule TCPRoute do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_many :match, L4MatchAttributes
      embeds_many :route, RouteDestination
    end
  end

  defmodule TLSMatchAttributes do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :destinationSubnets, {:array, :string}
      field :gateways, {:array, :string}
      field :port, :integer
      field :sniHosts, {:array, :string}
      field :sourceLabels, :map
      field :sourceNamespace, :string
    end
  end

  defmodule TLSRoute do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      embeds_many :match, TLSMatchAttributes
      embeds_many :route, RouteDestination
    end
  end

  defmodule VirtualService do
    @moduledoc false
    use CommonCore, {:embedded_schema, derive_json: false}

    batt_embedded_schema do
      field :exportTo, {:array, :string}, default: []
      field :gateways, {:array, :string}, default: ["battery-istio/ingressgateway"]
      field :hosts, {:array, :string}, default: ["*"]
      embeds_many :http, HTTPRoute
      embeds_many :tcp, TCPRoute
      embeds_many :tls, TLSRoute
    end
  end

  defimpl Jason.Encoder,
    for: [
      Delegate,
      StringMatch,
      HTTPBody,
      HTTPDirectResponse,
      HTTPRedirect,
      HTTPRetry,
      Headers.HeaderOperations,
      Headers,
      L4MatchAttributes,
      Percent,
      HTTPFaultInjection.Abort,
      HTTPFaultInjection.Delay,
      HTTPFaultInjection,
      PortSelector,
      Destination,
      HTTPMirrorPolicy,
      HTTPRouteDestination,
      RegexRewrite,
      HTTPRewrite,
      RouteDestination,
      CorsPolicy,
      HTTPMatchRequest,
      HTTPRoute,
      TCPRoute,
      TLSMatchAttributes,
      TLSRoute,
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
