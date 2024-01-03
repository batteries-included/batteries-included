defmodule CommonCore.Util.Integer do
  @moduledoc false
  def to_integer(value) when is_integer(value), do: value
  def to_integer(value) when is_binary(value), do: String.to_integer(value)
  def to_integer(value) when is_float(value), do: trunc(value)
  def to_integer(value) when is_boolean(value), do: if(value, do: 1, else: 0)
  def to_integer(value) when is_nil(value), do: 0
end
