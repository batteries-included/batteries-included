defmodule CommonCore.StateSummary.AccessSpecTest do
  use ExUnit.Case

  defp state_summary(ip) do
    ingress_service = %{
      "metadata" => %{"name" => "istio-ingressgateway", "namespace" => "battery-istio"},
      "status" => %{
        "loadBalancer" => %{
          "ingress" => [%{"ip" => ip}]
        }
      }
    }

    %CommonCore.StateSummary{
      kube_state: %{service: [ingress_service]},
      batteries: [
        %CommonCore.Batteries.SystemBattery{
          type: :istio,
          config: %CommonCore.Batteries.IstioConfig{namespace: "battery-istio"}
        }
      ]
    }
  end

  describe "new" do
    test "won't create a new AccessSpec if the hostname is invalid" do
      state_summary = state_summary("127.0.0.1")
      assert {:error, "Invalid hostname"} == CommonCore.StateSummary.AccessSpec.new(state_summary)
    end

    test "works with a valid hostname" do
      state_summary = state_summary("100.0.0.1")
      assert {:ok, _} = CommonCore.StateSummary.AccessSpec.new(state_summary)
    end
  end
end
