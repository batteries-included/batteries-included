defmodule EventCenter.KubeState do
  alias Phoenix.PubSub

  @pubsub EventCenter.KubeState.PubSub

  defmodule Payload do
    defstruct action: nil,
              resource: nil,
              new_resource_list: []
  end

  def broadcast(resource_type, %Payload{} = payload) do
    PubSub.broadcast(@pubsub, topic(resource_type), payload)
  end

  def subscribe(resource_type) when is_atom(resource_type), do: subscribe(topic(resource_type))

  def subscribe(resource_type) when is_binary(resource_type),
    do: PubSub.subscribe(@pubsub, resource_type)

  defp topic(resource_type), do: Atom.to_string(resource_type)
end
