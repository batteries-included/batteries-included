defmodule Verify.SessionURLAgent do
  @moduledoc false
  use Agent

  @me __MODULE__

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: @me)
  end

  # This would be a Wallaby.Session.t() struct but it is test only so can't use here
  @spec get(struct() | String.t()) :: String.t()
  def get(%{} = session), do: get(session.id)
  def get(session_id) when is_binary(session_id), do: Agent.get(@me, &Map.get(&1, session_id))

  # This would be a Wallaby.Session.t() struct but it is test only so can't use here
  @spec put(struct() | String.t(), String.t()) :: :ok
  def put(%{} = session, url), do: put(session.id, url)
  def put(session_id, url) when is_binary(session_id), do: Agent.update(@me, &Map.put(&1, session_id, url))
end
