defmodule CommonCore.Resources.CopyTest do
  use ExUnit.Case

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.CopyDown

  def deployment do
    :deployment
    |> B.build_resource()
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

  describe "CommonCore.Resources.CopyLabels" do
    test "Can copy labels for deployment" do
      assert deployment() != CopyDown.copy_labels_downward(deployment())
    end
  end
end
