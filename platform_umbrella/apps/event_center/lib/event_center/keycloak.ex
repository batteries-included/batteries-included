defmodule EventCenter.Keycloak do
  @moduledoc """
  This PubSub gets events about what we pushed to the KeyCloak API.
  """
  use TypedStruct

  alias EventCenter.Keycloak.Payload
  alias Phoenix.PubSub

  @pubsub EventCenter.Keycloak.PubSub

  @allowed_actions [
    :create_client,
    :create_realm,
    :create_user,
    :reset_user_password,
    :update_client,
    :update_required_action,
    :update_flow_execution
  ]

  typedstruct module: Payload do
    field :action, atom()
    field :resource, map()
  end

  @spec broadcast(Payload.t()) :: :ok | {:error, term}
  def broadcast(%Payload{action: action} = payload) when action in @allowed_actions do
    PubSub.broadcast(@pubsub, clean_topic(action), payload)
  end

  @spec broadcast!(Payload.t()) :: :ok
  def broadcast!(%Payload{action: action} = payload) when action in @allowed_actions do
    PubSub.broadcast!(@pubsub, clean_topic(action), payload)
  end

  @spec subscribe(binary() | atom()) :: :ok | {:error, term()}
  def subscribe(topic) do
    PubSub.subscribe(@pubsub, clean_topic(topic))
  end

  defp clean_topic(topic) when is_atom(topic), do: Atom.to_string(topic)
  defp clean_topic(topic), do: topic
end
