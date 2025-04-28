defmodule Verify.PostgresTest do
  use Verify.TestCase, async: false

  @moduletag :cluster_test

  verify "can start a postgres cluster", %{session: session, control_url: url} do
    cluster_name = "int-test-#{:rand.uniform(10_000)}"

    session
    |> visit(url <> "/postgres/new")
    |> assert_has(Query.text("New Postgres Cluster"))
    |> fill_in(Query.text_field("cluster[name]"), with: cluster_name)
    # Why is the cluster name still filled in with the suggested name here
    # This has to be a wallaby bug
    |> click(Query.button("Save"))
    # Make sure that the postres cluster show page title is there
    |> assert_has(Query.text("Postgres Cluster", minimum: 1))
    # Assert that we are on the correct cluster show page
    # |> assert_text(cluster_name)
    # Make sure that this page has the kubernetes elements
    |> assert_has(Query.text("Pods"))
    |> click(Query.text("Pods"))
    # Assert that the first pod for the cluster is there.
    |> assert_has(Query.css("tr:first-child", text: "#{cluster_name}-1"))
    |> click(Query.text("Overview"))
    |> assert_has(Query.css("h3", text: "Postgres Cluster"))

    # Assert that we have gotten to the show page
    path = current_path(session)
    assert path =~ ~r/\/postgres\/[\d\w-]+\/show$/
  end

  verify "choosing a different size update display", %{session: session, control_url: url} do
    session
    |> visit(url <> "/postgres/new")
    |> assert_has(Query.text("New Postgres Cluster"))
    |> find(Query.select("Size"), fn select ->
      click(select, Query.option("Huge"))
    end)
    |> assert_has(Query.text("1.0TB"))
  end

  verify "can add a user", %{session: session, control_url: url} do
    test_username = "testuser-#{:rand.uniform(10_000)}"

    session
    |> visit(url <> "/postgres/new")
    |> assert_has(Query.text("New Postgres Cluster"))
    |> click(Query.button("New User"))
    |> fill_in(Query.text_field("pg_user[username]"), with: test_username)
    |> click(Query.button("Add User"))
    |> assert_has(Query.css("table tbody tr", count: 2))
    |> assert_has(Query.text(test_username, minimum: 1))
    |> find(Query.select("Owner"), fn select ->
      # We can select the user we just created as the database owner
      click(select, Query.option(test_username))
    end)
  end
end
