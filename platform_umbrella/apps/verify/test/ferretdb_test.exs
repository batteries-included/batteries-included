defmodule Verify.FerretDBTest do
  use Verify.TestCase, async: false, batteries: ~w(ferretdb)a

  @new_path "/ferretdb/new"
  @new_ferretdb_header h3("New FerretDB/MongoDB Compatible Service")
  @name_field "ferret_service[name]"
  @save_button Query.button("Save FerretDB Service")
  @size_select Query.select("Size")

  verify "can start a ferretdb cluster", %{session: session} do
    instance_name = "int-test-#{:rand.uniform(10_000)}"

    session
    |> create_pg_cluster(instance_name)
    # create new instance
    |> visit(@new_path)
    |> assert_has(@new_ferretdb_header)
    |> fill_in_name(@name_field, instance_name)
    |> find(Query.select("Postgres Cluster"), fn select ->
      click(select, Query.option(instance_name))
    end)
    |> click(@save_button)
    # verify show page
    |> assert_has(h3("Show FerretDB Service", minimum: 1))
    |> assert_has(h3(instance_name, minimum: 1))
    |> assert_path(~r/\/ferretdb\/[\d\w-]+\/show$/)
    # Assert that the first pod for the cluster is shown
    |> assert_has(Query.text("Pods"))
    |> click(Query.text("Pods"))
    |> assert_has(table_row(text: instance_name, count: 1))
    |> assert_pod_running(instance_name)
  end

  verify "choosing a different size update display", %{session: session} do
    session
    |> visit(@new_path)
    |> assert_has(@new_ferretdb_header)
    |> find(@size_select, fn select ->
      click(select, Query.option("Large"))
    end)
    |> assert_has(Query.text("2GB"))
  end
end
