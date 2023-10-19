defmodule CommonCore.OpenApi.VirtualServiceTest do
  use ExUnit.Case

  alias CommonCore.OpenApi.IstioVirtualService.Destination
  alias CommonCore.OpenApi.IstioVirtualService.HTTPMatchRequest
  alias CommonCore.OpenApi.IstioVirtualService.HTTPRoute
  alias CommonCore.OpenApi.IstioVirtualService.HTTPRouteDestination
  alias CommonCore.OpenApi.IstioVirtualService.StringMatch
  alias CommonCore.OpenApi.IstioVirtualService.VirtualService

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
      assert virtual_service.gateways == ["battery-istio/ingress"]
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
