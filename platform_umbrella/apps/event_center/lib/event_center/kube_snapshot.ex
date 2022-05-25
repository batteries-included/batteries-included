defmodule EventCenter.KubeSnapshot do
  alias Phoenix.PubSub

  @pubsub EventCenter.KubeSnapshot.PubSub
  @topic "snapshots"

  defmodule Payload do
    defstruct snapshot: nil
  end

  @spec broadcast(any()) :: :ok | {:error, any()}
  def broadcast(snapshot) do
    PubSub.broadcast(@pubsub, @topic, %Payload{snapshot: snapshot})
  end

  @spec subscribe() :: :ok | {:error, {:already_registered, pid()}}
  def subscribe, do: PubSub.subscribe(@pubsub, @topic)
end
