defmodule Verify.ForegejoTest do
  use Verify.TestCase,
    async: false,
    batteries: [
      # the override config is just for testing that we can override during testing
      forgejo: %{admin_username: "user", admin_password: "pass"}
    ],
    images: ~w(forgejo)a

  verify "forgejo is running", %{session: session} do
    session
    |> assert_pod_succeeded("pg-forgejo-1-initdb")
    |> assert_pod_running("pg-forgejo-1")
    |> assert_pods_in_sts_running("battery-core", "forgejo")
    # now let's make sure we can access the running service
    |> visit("/devtools")
    |> click_external(Query.css("a", text: "Forgejo"))
    # find the link to the website in the footer
    |> assert_has(Query.text("Powered by Forgejo"))
  end
end
