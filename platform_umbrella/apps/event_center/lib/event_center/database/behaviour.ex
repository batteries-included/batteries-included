defmodule EventCenter.Database.Behaviour do
  @moduledoc """
  Behaviour for EventCenter database event broadcasting. Defines callbacks for broadcasting database changes and subscribing to topics.
  """

  @doc """
  Returns list of allowed database actions. Actions include insert, update, delete, and multi operations.
  """
  @callback allowed_actions() :: list(atom())

  @doc """
  Returns list of allowed data sources. Sources include various system batteries and services that can emit database events.
  """
  @callback allowed_sources() :: list(atom())

  @doc """
  Broadcasts database events to subscribers. Publishes changes from specified source with action and object data.
  """
  @callback broadcast(source :: atom(), action :: atom(), object :: any()) :: :ok | {:error, any()}

  @doc """
  Subscribes to database events on specified topic. Allows processes to receive notifications of database changes.
  """
  @callback subscribe(topic :: binary() | atom()) :: :ok | {:error, any()}
end
