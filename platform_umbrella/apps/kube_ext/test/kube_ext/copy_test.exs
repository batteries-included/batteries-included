defmodule KubeExt.CopyTest do
  use ExUnit.Case

  alias KubeExt.CopyDown
  alias KubeExt.Builder, as: B

  def deployment do
    B.build_resource(:deployment)
    |> B.name("my_deployment")
    |> B.app_labels("my-app")
    |> B.namespace("battery-core")
    |> B.spec(%{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "my-app"
        }
      },
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "my-app"
          }
        }
      }
    })
  end

  describe "KubeExt.CopyLabels" do
    test "Can copy labels for deployment" do
      assert deployment() != CopyDown.copy_labels_downward(deployment())
    end
  end
end
