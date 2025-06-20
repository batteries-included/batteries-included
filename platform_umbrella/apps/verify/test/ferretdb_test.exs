defmodule Verify.FerretDBTest do
  use Verify.TestCase, async: false, batteries: ~w(ferretdb)a, images: ~w(ferretdb)a

  @new_path "/ferretdb/new"
  @new_ferretdb_header h3("New FerretDB/MongoDB Compatible Service")
  @name_field "ferret_service[name]"
  @save_button Query.button("Save FerretDB Service")
  @size_select Query.select("Size")

  verify "can start a ferretdb cluster", %{session: session} do
    instance_name = "int-test-#{:rand.uniform(10_000)}"
    start_cluster(session, instance_name)
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

  describe "with timeline installed" do
    setup %{battery_install_worker: worker} do
      :ok = install_batteries(worker, :timeline)

      on_exit(fn -> uninstall_batteries(worker, :timeline) end)
      :ok
    end

    verify "installed cluster has timeline", %{session: session} do
      instance_name = "int-test-#{:rand.uniform(10_000)}"

      session
      |> start_cluster(instance_name)
      # Assert that the first pod for the cluster is shown
      |> assert_has(Query.text("Edit Versions"))
      |> click(Query.text("Edit Versions"))
      |> assert_has(table_row(text: "created", count: 1))
    end
  end

  defp start_cluster(session, instance_name) do
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
end
