defmodule ControlServerWeb.ResourceHTMLHelperTest do
  use ControlServerWeb.ConnCase

  import CommonCore.ResourceFactory
  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  test "resource_path/2" do
    resource = build(:pod)

    assert resource_path(resource) ==
             "/kube/#{resource |> kind() |> String.downcase()}/#{namespace(resource)}/#{name(resource)}/show"
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
