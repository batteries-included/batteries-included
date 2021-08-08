defmodule KubeServices.WorkerTest do
  use ExUnit.Case
  doctest KubeServices.Worker

  alias KubeServices.Worker.ApplyState
  alias KubeExt.Hashing

  defp resource(%{} = content) do
    content |> Map.put("metadata", %{"annotations" => %{}}) |> Hashing.decorate_content_hash()
  end

  test "ApplyState.needs_apply" do
    res = resource(%{test: 100})
    no_match_res = resource(%{test: 200})
    ap_match = %ApplyState{last_result: {:ok, nil}, resource: res}
    ap_no_match = %ApplyState{last_result: {:error, "Bad res"}, resource: no_match_res}
    ap_err = %ApplyState{last_result: {:error, "Bad res"}, resource: res}

    assert ApplyState.needs_apply(ap_match, res) == false
    assert ApplyState.needs_apply(ap_no_match, res) == true
    assert ApplyState.needs_apply(ap_err, res) == true
  end
end
