defmodule ControlServerWeb.ResouceHTMLHelperTest do
  use ControlServerWeb.ConnCase

  import CommonCore.Resources.FieldAccessors
  import ControlServer.ResourceFixtures
  import ControlServerWeb.ResourceHTMLHelper

  test "resource_show_path/2" do
    resource = resource_fixture()

    assert resource_show_path(resource) ==
             "/kube/#{resource |> kind() |> String.downcase()}/#{namespace(resource)}/#{name(resource)}"
  end

  describe "to_html_id/1" do
    test "to_html_id/1 converts resource to id string" do
      resource = %{"kind" => "Pod", "metadata" => %{"namespace" => "default", "name" => "my-pod"}}
      assert to_html_id(resource) == "pod_default_my-pod"
    end

    test "to_html_id/1 converts to lowercase" do
      resource = %{"kind" => "POD", "metadata" => %{"namespace" => "DEFAULT", "name" => "MY-POD"}}
      assert to_html_id(resource) == "pod_default_my-pod"
    end

    test "to_html_id/1 handles missing fields" do
      resource = %{"kind" => "Pod"}
      assert to_html_id(resource) == "pod"
    end
  end
end
