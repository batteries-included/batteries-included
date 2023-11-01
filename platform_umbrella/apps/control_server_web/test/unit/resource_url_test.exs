defmodule ControlServerWeb.ResouceURLTest do
  use ControlServerWeb.ConnCase

  import ControlServerWeb.ResourceFixtures
  import ControlServerWeb.ResourceURL

  alias ControlServerWeb.Resource

  test "resource_show_path/2" do
    resource = resource_fixture()

    assert resource_show_path(resource) ==
             "/kube/#{resource |> Resource.kind() |> String.downcase()}/#{Resource.namespace(resource)}/#{Resource.name(resource)}"
  end
end
