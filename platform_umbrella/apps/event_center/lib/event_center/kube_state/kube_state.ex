defmodule EventCenter.KubeState do
  @moduledoc false
  @behaviour EventCenter.KubeState.Behaviour

  use TypedStruct

  alias Phoenix.PubSub

  @pubsub EventCenter.KubeState.PubSub

  typedstruct module: Payload do
    field :action, atom()
    field :resource, map()
  end

  def broadcast(resource_type, %Payload{} = payload) do
    PubSub.broadcast(@pubsub, topic(resource_type), payload)
  end

  def broadcast!(resource_type, %Payload{} = payload) do
    PubSub.broadcast!(@pubsub, topic(resource_type), payload)
  end

  def subscribe(resource_type) when is_atom(resource_type), do: subscribe(topic(resource_type))

  def subscribe(resource_type) when is_binary(resource_type), do: PubSub.subscribe(@pubsub, resource_type)

  defp topic(resource_type), do: Atom.to_string(resource_type)
end
