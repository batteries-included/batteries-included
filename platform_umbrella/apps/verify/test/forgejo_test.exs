defmodule Verify.ForegejoTest do
  use Verify.TestCase, async: false, batteries: ~w(forgejo)a

  verify "forgejo is running", %{session: session} do
    session
    |> assert_pod_running("pg-forgejo-1")
    |> assert_pod_running("forgejo-0")
  end
end
