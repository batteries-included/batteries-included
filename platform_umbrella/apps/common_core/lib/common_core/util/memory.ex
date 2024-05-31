defmodule CommonCore.Util.Memory do
  @moduledoc false

  @doc """
  Converts another unit or a human-readable string to bytes.
  Returns `:error` if the string could not be parsed.

  ## Examples

      iex> to_bytes("1KB")
      1024

      iex> to_bytes(1, :MB)
      1048576

  """
  def to_bytes(value) when is_binary(value) do
    case Float.parse(value) do
      {x, unit} -> x |> to_bytes(String.to_existing_atom(unit)) |> round()
      :error -> :error
    end
  end

  def to_bytes(value, unit) do
    value * multiplier(unit)
  end

  @doc """
  Converts bytes to another unit with an optional float precision.

  ## Examples

      iex> from_bytes(1024, :KB)
      1.0

  """
  def from_bytes(value, unit, precision \\ 1) do
    Float.round(value / multiplier(unit), precision)
  end

  @doc """
  Converts bytes to a human-readable string.

  ## Examples

      iex> humanize(1024)
      "1KB"

  """
  def humanize(bytes, smart_rounding \\ true)

  def humanize(nil, _), do: nil

  def humanize(bytes, smart_rounding) when is_binary(bytes) do
    humanize(String.to_integer(bytes), smart_rounding)
  end

  def humanize(bytes, smart_rounding) do
    cond do
      bytes >= multiplier(:TB) -> do_humanize(bytes, :TB, smart_rounding)
      bytes >= multiplier(:GB) -> do_humanize(bytes, :GB, smart_rounding)
      bytes >= multiplier(:MB) -> do_humanize(bytes, :MB, smart_rounding)
      bytes >= multiplier(:KB) -> do_humanize(bytes, :KB, smart_rounding)
      bytes >= 0 -> do_humanize(bytes, :B, smart_rounding)
      true -> :error
    end
  end

  defp do_humanize(bytes, unit, smart_rounding) do
    value = bytes / multiplier(unit)
    value = if smart_rounding, do: do_round(value, unit), else: round(value)

    "#{value}#{unit}"
  end

  defp do_round(value, :TB), do: Float.round(value, 1)
  defp do_round(value, :KB), do: Float.round(value, 1)
  defp do_round(value, _), do: round(value)

  defp multiplier(:TB), do: Integer.pow(1024, 4)
  defp multiplier(:GB), do: Integer.pow(1024, 3)
  defp multiplier(:MB), do: Integer.pow(1024, 2)
  defp multiplier(:KB), do: 1024
  defp multiplier(:B), do: 1

  @doc """
  Returns a list of tuples for use in select input options.
  """
  def bytes_as_select_options(byte_options) do
    Enum.map(byte_options, &{humanize(&1, false), &1})
  end
end
