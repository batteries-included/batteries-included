defmodule Verify.ForegejoTest do
  use Verify.TestCase,
    async: false,
    batteries: [
      # the override config is just for testing that we can override during testing
      forgejo: %{admin_username: "user", admin_password: "pass"}
    ]

  verify "forgejo is running", %{session: session} do
    session
    # this also asserts on e.g. pg-forgejo-1-initdb, unfortunately
    |> assert_pod_running("pg-forgejo-1")
    # so check it again?
    |> assert_pod_running("pg-forgejo-1")
    # the actual pod won't come up until the DB is available
    |> assert_pod_running("forgejo-0")
    # now let's make sure we can access the running service
    |> visit("/devtools")
    |> click_external(Query.css("a", text: "Forgejo"))
    # find the link to the website in the footer
    |> assert_has(Query.text("Powered by Forgejo"))
  end
end
