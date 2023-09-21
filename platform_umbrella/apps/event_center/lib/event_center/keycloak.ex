defmodule EventCenter.Keycloak do
  @moduledoc """
  This PubSub gets events about what we pushed to the KeyCloak API.
  """
  use TypedStruct

  alias Phoenix.PubSub

  @pubsub EventCenter.Keycloak.PubSub

  @allowed_actions [
    :create_client,
    :create_realm,
    :create_user,
    :reset_user_password,
    :update_client
  ]

  typedstruct module: Payload do
    field :action, atom()
    field :resource, map()
  end

  def broadcast(%Payload{action: action, resource: resource}) when action in @allowed_actions do
    PubSub.broadcast(@pubsub, clean_topic(action), resource)
  end

  def broadcast!(%Payload{action: action, resource: resource}) when action in @allowed_actions do
    PubSub.broadcast!(@pubsub, clean_topic(action), resource)
  end

  def subscribe(topic) do
    PubSub.subscribe(@pubsub, clean_topic(topic))
  end

  def clean_topic(topic) when is_atom(topic), do: Atom.to_string(topic)
  def clean_topic(topic), do: topic
end
