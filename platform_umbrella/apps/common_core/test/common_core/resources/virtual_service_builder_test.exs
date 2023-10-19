defmodule CommonCore.Resources.VirtualServiceBuilderTest do
  use ExUnit.Case

  alias CommonCore.OpenApi.IstioVirtualService.Destination
  alias CommonCore.OpenApi.IstioVirtualService.HTTPMatchRequest
  alias CommonCore.OpenApi.IstioVirtualService.HTTPRewrite
  alias CommonCore.OpenApi.IstioVirtualService.HTTPRoute
  alias CommonCore.OpenApi.IstioVirtualService.HTTPRouteDestination
  alias CommonCore.OpenApi.IstioVirtualService.L4MatchAttributes
  alias CommonCore.OpenApi.IstioVirtualService.PortSelector
  alias CommonCore.OpenApi.IstioVirtualService.RouteDestination
  alias CommonCore.OpenApi.IstioVirtualService.StringMatch
  alias CommonCore.OpenApi.IstioVirtualService.TCPRoute
  alias CommonCore.OpenApi.IstioVirtualService.VirtualService
  alias CommonCore.Resources.VirtualServiceBuilder, as: V

  describe "prefix/4" do
    test "adds a route with the given prefix" do
      virtual_service = %VirtualService{}
      prefix = "/foo"
      service_host = "my-service"
      service_port = 80

      updated_vs = V.prefix(virtual_service, prefix, service_host, service_port)

      assert updated_vs.http == [
               %HTTPRoute{
                 name: "_foo",
                 match: [%HTTPMatchRequest{uri: %StringMatch{prefix: "/foo"}}],
                 route: [
                   %HTTPRouteDestination{
                     destination: %Destination{host: "my-service", port: %PortSelector{number: 80}}
                   }
                 ]
               }
             ]
    end

    test "can build multiple routes with different prefixes" do
      final =
        VirtualService.new!()
        |> V.prefix("/foo", "service-a", 80)
        |> V.prefix("/bar", "service-b", 8080)

      assert final.http == [
               %HTTPRoute{
                 name: "_foo",
                 match: [%HTTPMatchRequest{uri: %StringMatch{prefix: "/foo"}}],
                 route: [
                   %HTTPRouteDestination{
                     destination: %Destination{host: "service-a", port: %PortSelector{number: 80}}
                   }
                 ]
               },
               %HTTPRoute{
                 name: "_bar",
                 match: [%HTTPMatchRequest{uri: %StringMatch{prefix: "/bar"}}],
                 route: [
                   %HTTPRouteDestination{
                     destination: %Destination{host: "service-b", port: %PortSelector{number: 8080}}
                   }
                 ]
               }
             ]
    end
  end

  describe "rewriting/4" do
    test "adds a rewrite route" do
      virtual_service = %VirtualService{}
      prefix = "/foo"
      service_host = "my-service"
      service_port = 80

      updated_vs = V.rewriting(virtual_service, prefix, service_host, service_port)

      assert updated_vs.http == [
               %HTTPRoute{
                 name: "rewriting:_foo",
                 rewrite: %HTTPRewrite{uri: "/"},
                 match: [
                   %HTTPMatchRequest{uri: %StringMatch{prefix: "/foo/"}},
                   %HTTPMatchRequest{uri: %StringMatch{prefix: "/foo"}}
                 ],
                 route: [
                   %HTTPRouteDestination{destination: %Destination{host: "my-service", port: %PortSelector{number: 80}}}
                 ]
               }
             ]
    end
  end

  describe "tcp/4" do
    test "tcp/4 adds a TCP route" do
      virtual_service = %VirtualService{}
      external_port = 80
      service_host = "grafana.svc"
      service_port = 8080

      updated_service =
        V.tcp(virtual_service, external_port, service_host, service_port)

      assert updated_service.tcp == [
               %TCPRoute{
                 match: [
                   %L4MatchAttributes{port: 80}
                 ],
                 route: [
                   %RouteDestination{
                     destination: %Destination{
                       host: "grafana.svc",
                       port: %PortSelector{number: 8080}
                     }
                   }
                 ]
               }
             ]
    end
  end
end
