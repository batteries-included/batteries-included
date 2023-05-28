defmodule EventCenter.KubeSnapshot do
  use TypedStruct

  alias Phoenix.PubSub

  @pubsub EventCenter.KubeSnapshot.PubSub
  @topic "snapshots"

  typedstruct module: Payload do
    field :snapshot, map(), default: nil, enforce: false
  end

  @spec broadcast(any()) :: :ok | {:error, any()}
  def broadcast(snapshot) do
    PubSub.broadcast(@pubsub, @topic, %Payload{snapshot: snapshot})
  end

  @spec subscribe() :: :ok | {:error, {:already_registered, pid()}}
  def subscribe, do: PubSub.subscribe(@pubsub, @topic)
end
