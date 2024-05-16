defmodule EventCenter.SystemStateSummaryTest do
  use ExUnit.Case

  test "publishes event to subscribers" do
    payload = CommonCore.StateSummary.new!()

    EventCenter.SystemStateSummary.subscribe()
    EventCenter.SystemStateSummary.broadcast(payload)
    assert_receive ^payload
  end
end
