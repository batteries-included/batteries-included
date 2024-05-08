defmodule CommonCore.OpenAPI.VirtualServiceTest do
  use ExUnit.Case

  alias CommonCore.OpenAPI.IstioVirtualService.Destination
  alias CommonCore.OpenAPI.IstioVirtualService.HTTPMatchRequest
  alias CommonCore.OpenAPI.IstioVirtualService.HTTPRoute
  alias CommonCore.OpenAPI.IstioVirtualService.HTTPRouteDestination
  alias CommonCore.OpenAPI.IstioVirtualService.StringMatch
  alias CommonCore.OpenAPI.IstioVirtualService.VirtualService

  describe "VirtualService" do
    test "creates a valid VirtualService struct" do
      {:ok, virtual_service} =
        VirtualService.new(
          exportTo: ["gateway1", "gateway2"],
          gateways: ["gateway1", "gateway2"],
          hosts: ["example.com"],
          http: [],
          tcp: [],
          tls: []
        )

      assert virtual_service.exportTo == ["gateway1", "gateway2"]
      assert virtual_service.gateways == ["gateway1", "gateway2"]
      assert virtual_service.hosts == ["example.com"]
      assert virtual_service.http == []
      assert virtual_service.tcp == []
      assert virtual_service.tls == []
    end

    test "sets default values" do
      virtual_service = VirtualService.new!()

      assert virtual_service.exportTo == []
      assert virtual_service.gateways == ["battery-istio/ingressgateway"]
      assert virtual_service.hosts == ["*"]
      assert virtual_service.http == []
      assert virtual_service.tcp == []
      assert virtual_service.tls == []
    end
  end

  describe "HTTPRoute" do
    test "encodes to JSON" do
      # Use a mix of struct creation methods to ensure test coverage
      route =
        HTTPRoute.new!(%{
          name: "my-route",
          match: [
            HTTPMatchRequest.new!(%{uri: %StringMatch{exact: "/foo"}})
          ],
          route: [
            HTTPRouteDestination.new!(%{
              destination: %Destination{
                host: "my-service"
              }
            })
          ]
        })

      json = Jason.encode!(route)

      assert json ==
               Jason.encode!(%{
                 "name" => "my-route",
                 "match" => [
                   %{
                     "uri" => %{
                       "exact" => "/foo"
                     }
                   }
                 ],
                 "route" => [
                   %{
                     "destination" => %{
                       "host" => "my-service"
                     }
                   }
                 ]
               })
    end
  end
end
