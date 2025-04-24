defmodule Verify.RedisTest do
  use Verify.TestCase, async: false

  @moduletag :cluster_test

  @new_path "/redis/new"
  @new_redis_header Query.css("h3", text: "New Redis Instance")
  @name_field Query.text_field("redis_instance[name]")
  @save_button Query.button("Save Redis")
  @size_select Query.select("Size")
  @type_select Query.select("Type")

  defp show_page_header(instance_name), do: Query.css("h3", text: instance_name)

  test "can start a standalone redis instance", %{session: session} do
    instance_name = "int-test-#{:rand.uniform(10_000)}"

    session
    # create new instance
    |> visit(@new_path)
    |> assert_has(@new_redis_header)
    |> fill_in(@name_field, with: instance_name)
    |> click(@save_button)
    # verify show page
    |> assert_has(show_page_header(instance_name))
    # Assert that the first pod for the cluster is shown
    |> assert_has(Query.css("tr:first-child", text: "#{instance_name}-0"))

    # Assert that we have gotten to the show page
    path = current_path(session)
    assert path =~ ~r/\/redis\/[\d\w-]+\/show$/
  end

  test "choosing a different size update display", %{session: session} do
    session
    |> visit(@new_path)
    |> assert_has(@new_redis_header)
    |> find(@size_select, fn select ->
      click(select, Query.option("Large"))
    end)
    |> assert_has(Query.text("1GB"))
  end

  test "can start a replication redis instance", %{session: session} do
    instance_name = "int-test-#{:rand.uniform(10_000)}"

    session
    # create new
    |> visit(@new_path)
    |> assert_has(@new_redis_header)
    |> fill_in(@name_field, with: instance_name)
    |> find(@type_select, fn select ->
      click(select, Query.option("Cluster"))
    end)
    |> click(@save_button)
    # verify
    |> assert_has(show_page_header(instance_name))
    # check that we have both a leader and follower
    |> assert_has(Query.css("tr", text: "#{instance_name}-leader-0"))
    |> assert_has(Query.css("tr", text: "#{instance_name}-follower-0"))

    # Assert that we have gotten to the show page
    path = current_path(session)
    assert path =~ ~r/\/redis\/[\d\w-]+\/show$/
  end

  test "can start a redis cluster", %{session: session} do
    instance_name = "int-test-#{:rand.uniform(10_000)}"

    session
    # create new
    |> visit(@new_path)
    |> assert_has(@new_redis_header)
    |> fill_in(@name_field, with: instance_name)
    |> find(@type_select, fn select ->
      click(select, Query.option("Replication"))
    end)
    # how do we set the value of a slider?
    # |> set_value(Query.css(~s|input[type="range"]|), "2")
    |> click(@save_button)
    # verify
    |> assert_has(show_page_header(instance_name))
    # check that we have ~2~ 1 pods
    |> assert_has(Query.css("tr", text: "#{instance_name}", count: 1))

    # Assert that we have gotten to the show page
    path = current_path(session)
    assert path =~ ~r/\/redis\/[\d\w-]+\/show$/
  end
end
