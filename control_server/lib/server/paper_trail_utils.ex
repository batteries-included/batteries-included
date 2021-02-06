defmodule Server.PaperTrailUtils do
  @moduledoc """
  Papertrail is really useful for tracking the changes, but
  most code will assume the result of
  an ecto call is :Ok, EcotModel. This module helps with that.
  """

  def unwrap_papertrail({:ok, %{model: model, version: _version}}) do
    {:ok, model}
  end

  def unwrap_papertrail({:error, result}) do
    {:error, result}
  end
end
