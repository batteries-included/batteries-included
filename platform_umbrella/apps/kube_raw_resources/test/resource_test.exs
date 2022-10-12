defmodule KubeRawResources.ResourceTest do
  use ExUnit.Case

  alias KubeRawResources.Resource.ResourceState
  alias KubeExt.Hashing

  defp resource(%{} = content) do
    content |> Map.put("metadata", %{"annotations" => %{}}) |> Hashing.decorate()
  end

  test "ResourceState.needs_apply" do
    res = resource(%{test: 100})
    no_match_res = resource(%{test: 200})
    ap_match = %ResourceState{last_result: {:ok, nil}, resource: res}
    ap_no_match = %ResourceState{last_result: {:error, "Bad res"}, resource: no_match_res}
    ap_err = %ResourceState{last_result: {:error, "Bad res"}, resource: res}

    assert ResourceState.needs_apply(ap_match, res) == false
    assert ResourceState.needs_apply(ap_no_match, res) == true
    assert ResourceState.needs_apply(ap_err, res) == true
  end
end
