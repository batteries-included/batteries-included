defmodule HomeBase.Time do
  @moduledoc """
  Funtions to do useful things with datetimes/times that are fun/useful.
  """
  def truncate(%DateTime{} = dt, :hour) do
    %DateTime{dt | minute: 0, second: 0, microsecond: {0, 0}}
  end

  def truncate(%DateTime{} = dt, :month) do
    %DateTime{dt | day: 1, hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
  end
end
