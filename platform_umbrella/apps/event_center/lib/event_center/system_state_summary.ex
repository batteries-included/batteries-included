defmodule EventCenter.SystemStateSummary do
  alias Phoenix.PubSub

  @pubsub EventCenter.SystemStateSummary.PubSub
  @topic "new_summary"

  def broadcast(summary) do
    PubSub.broadcast(@pubsub, @topic, summary)
  end

  def subscribe,
    do: PubSub.subscribe(@pubsub, @topic)
end
