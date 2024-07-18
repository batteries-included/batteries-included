defmodule EventCenter.DatabasePubSubTest do
  use ExUnit.Case

  test "publishes event to subscribers" do
    payload = %{id: 1, name: "Event 1"}

    EventCenter.Database.subscribe(:traditional_service)
    EventCenter.Database.broadcast(:traditional_service, :insert, payload)
    assert_receive {:insert, ^payload}
  end

  test "doesn't publish to unsubscribed topics" do
    payload = %{id: 1, name: "Event 1"}

    EventCenter.Database.subscribe(:traditional_service)
    EventCenter.Database.broadcast(:ferret_service, :insert, payload)
    refute_receive {:insert, ^payload}
  end
end
