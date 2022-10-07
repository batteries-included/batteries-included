defmodule EventCenter.Database do
  alias Phoenix.PubSub

  @pubsub EventCenter.Database.PubSub

  @allowed_actions [:insert, :update, :delete, :multi]
  @allowed_sources [
    :jupyter_notebook,
    :knative_service,
    :postgres_cluster,
    :redis_cluster,
    :system_battery,
    :timeline_event
  ]

  def allowed_actions, do: @allowed_actions
  def allowed_sources, do: @allowed_sources

  def broadcast(source, action, object) when action in @allowed_actions do
    PubSub.broadcast(@pubsub, clean_topic(source), {action, clean(object)})
  end

  def subscribe(topic) do
    PubSub.subscribe(@pubsub, clean_topic(topic))
  end

  def clean(object) when is_struct(object), do: Map.from_struct(object)
  def clean(object), do: object

  def clean_topic(topic) when is_atom(topic), do: Atom.to_string(topic)
  def clean_topic(topic), do: topic
end
