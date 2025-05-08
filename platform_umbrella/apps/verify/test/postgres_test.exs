defmodule Verify.PostgresTest do
  use Verify.TestCase, async: false

  @new_postgres_path "/postgres/new"
  @new_postgres_header h3("New Postgres Cluster")

  verify "can start a postgres cluster", %{session: session} do
    cluster_name =
      "int-test-#{:rand.uniform(10_000)}"

    session
    |> create_pg_cluster(cluster_name)
    # verify show page
    |> assert_has(h3("Postgres Cluster", minimum: 1))
    |> assert_has(h3(cluster_name))
    |> assert_path(~r/\/postgres\/[\d\w-]+\/show$/)
    # Make sure that this page has the kubernetes elements
    |> assert_has(Query.text("Pods"))
    |> click(Query.text("Pods"))
    # Assert that the first pod for the cluster is there.
    |> assert_has(table_row(text: "#{cluster_name}-1", count: 1))
    |> assert_pod_running("#{cluster_name}-1")
  end

  verify "choosing a different size update display", %{session: session} do
    session
    |> visit(@new_postgres_path)
    |> assert_has(@new_postgres_header)
    |> find(Query.select("Size"), fn select ->
      click(select, Query.option("Huge"))
    end)
    |> assert_has(Query.text("1.0TB"))
  end

  verify "can add a user", %{session: session} do
    test_username = "testuser-#{:rand.uniform(10_000)}"

    session
    |> visit(@new_postgres_path)
    |> assert_has(@new_postgres_header)
    |> click(Query.button("New User"))
    |> fill_in(Query.text_field("pg_user[username]"), with: test_username)
    |> click(Query.button("Add User"))
    |> assert_has(table_row(count: 2))
    |> assert_has(Query.text(test_username, minimum: 1))
    |> find(Query.select("Owner"), fn select ->
      # We can select the user we just created as the database owner
      click(select, Query.option(test_username))
    end)
  end
end
