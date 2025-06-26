defmodule Verify.GrafanaTest do
  use Verify.TestCase, async: false, batteries: ~w(grafana)a, images: ~w(grafana)a

  verify "grafana is running", %{session: session} do
    session
    |> assert_pod_running("grafana-")
    |> visit("/monitoring")
    |> click_external(Query.css("a", text: "Grafana"))
    # find the link to the website in the footer
    |> assert_has(Query.css("h1", text: "Welcome to Grafana"))
  end
end
