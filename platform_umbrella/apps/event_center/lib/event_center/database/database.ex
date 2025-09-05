defmodule EventCenter.Database do
  @moduledoc false
  @behaviour EventCenter.Database.Behaviour

  alias Phoenix.PubSub

  @pubsub EventCenter.Database.PubSub

  # WAIT!
  # If you are changing here then also change in CommonCore.Timeline
  @allowed_actions [:insert, :update, :delete, :multi]
  # WAIT!
  # If you are changing here then also change in CommonCore.Timeline
  @allowed_sources [
    :jupyter_notebook,
    :knative_service,
    :postgres_cluster,
    :redis_cluster,
    :system_battery,
    :timeline_event,
    :ferret_service,
    :traditional_service,
    :model_instance,
    :issue
  ]

  def allowed_actions, do: @allowed_actions
  def allowed_sources, do: @allowed_sources

  def broadcast(source, action, object) when action in @allowed_actions do
    PubSub.broadcast(@pubsub, clean_topic(source), {action, clean(object)})
  end

  def subscribe(topic) do
    PubSub.subscribe(@pubsub, clean_topic(topic))
  end

  defp clean(object) when is_struct(object) do
    object
    |> Map.from_struct()
    |> Map.drop([:__meta__, :__struct__])
  end

  defp clean(object), do: object

  defp clean_topic(topic) when is_atom(topic), do: Atom.to_string(topic)
  defp clean_topic(topic), do: topic
end
