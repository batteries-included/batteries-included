defmodule EventCenter.Keycloak do
  @moduledoc """
  This PubSub gets events about what we pushed to the KeyCloak API.
  """
  alias Phoenix.PubSub

  @pubsub EventCenter.Keycloak.PubSub

  @allowed_actions [:create_user, :create_realm, :reset_user_password]

  def broadcast(action, object) when action in @allowed_actions do
    PubSub.broadcast(@pubsub, clean_topic(action), object)
  end

  def subscribe(topic) do
    PubSub.subscribe(@pubsub, clean_topic(topic))
  end

  def clean_topic(topic) when is_atom(topic), do: Atom.to_string(topic)
  def clean_topic(topic), do: topic
end
