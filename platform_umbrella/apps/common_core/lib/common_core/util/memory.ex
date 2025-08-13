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
      {x, unit} -> to_bytes(x, String.to_existing_atom(unit))
      :error -> :error
    end
  end

  def to_bytes(value, unit \\ :B) do
    round(value * multiplier(unit))
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

  def humanize(nil, _), do: "0B"
  def humanize("", _), do: "0B"

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
  # Kubernetes/IEC binary units
  defp multiplier(:Ti), do: Integer.pow(1024, 4)
  defp multiplier(:Gi), do: Integer.pow(1024, 3)
  defp multiplier(:Mi), do: Integer.pow(1024, 2)
  defp multiplier(:Ki), do: 1024

  @doc """
  Returns a list of tuples for use in select input options.
  """
  def bytes_as_select_options(byte_options) do
    Enum.map(byte_options, &{humanize(&1, false), &1})
  end

  @doc """
  Calculates the relative value of a range slider when it's
  between two ticks. This is useful when the tick units are
  not proportional to the actual value of the slider. Returns
  the relative bytes, or `:error` if the value is out of bounds.

  For example, consider this range input:

      0GB         10GB       500GB        1TB         2TB
       |=====O-----|-----------|-----------|-----------|

  The raw value returned from that range input would be 12.5%
  of 2TB, or 256GB. But it should actually be 5GB, since it's
  halfway between 0GB and 10GB.

  ## Examples

      iex> ticks = [{"0GB", 0}, {"10GB", 0.25}, {"500GB", 0.5}, {"1TB", 0.75}, {"2TB", 1}]

      iex> "256GB" |> to_bytes() |> range_value_to_bytes(ticks) |> humanize()
      "5GB"

      iex> "3TB" |> to_bytes() |> range_value_to_bytes(ticks)
      :error

  """
  def range_value_to_bytes(value, [_ | _] = range_ticks) do
    min_bytes = min_range_value(range_ticks)
    max_bytes = max_range_value(range_ticks)

    if value < 0 || value > max_bytes do
      :error
    else
      do_range_value_to_bytes(value, range_ticks, min_bytes, max_bytes)
    end
  end

  defp do_range_value_to_bytes(bytes, range_ticks, min_bytes, max_bytes) do
    # get the percentage of range's current value
    target_percent = (bytes - min_bytes) / (max_bytes - min_bytes)

    # get the value's surrounding ticks if there are any (the window)
    {{bottom_bytes, bottom_percent}, {top_bytes, top_percent}} =
      get_window(range_ticks, max_bytes, fn {_, x} -> x >= target_percent end)

    # determine how far the value is into the window
    window_percent =
      case (top_percent - bottom_percent) * max_bytes do
        # value is an edge
        0 -> 1
        # value is not an edge
        window_bytes -> (bytes - max_bytes * bottom_percent) / window_bytes
      end

    round((top_bytes - bottom_bytes) * window_percent + bottom_bytes)
  end

  @doc """
  Calculates the absolute value of the range slider from a
  relative value. This does the opposite of `range_value_to_bytes/2`.
  Returns the absolute bytes, or `:error` if the value is out
  of bounds.

  ## Examples

      iex> ticks = [{"0GB", 0}, {"10GB", 0.25}, {"500GB", 0.5}, {"1TB", 0.75}, {"2TB", 1}]

      iex> "5GB" |> to_bytes() |> bytes_to_range_value(ticks) |> humanize()
      "256GB"

      iex> "3TB" |> to_bytes() |> bytes_to_range_value(ticks)
      :error

  """
  def bytes_to_range_value(nil, _), do: nil

  def bytes_to_range_value(value, [_ | _] = range_ticks) do
    min_bytes = min_range_value(range_ticks)
    max_bytes = max_range_value(range_ticks)

    cond do
      value < min_bytes ->
        0

      value > max_bytes ->
        max_bytes

      true ->
        do_bytes_to_range_value(value, range_ticks, max_bytes)
    end
  end

  defp do_bytes_to_range_value(bytes, range_ticks, max_bytes) do
    # get the value's surrounding ticks if there are any (the window)
    {{bottom_bytes, bottom_percent}, {top_bytes, top_percent}} =
      get_window(range_ticks, max_bytes, fn {x, _} -> to_bytes(x) >= bytes end)

    # determine how far the value is into the window
    window_bytes =
      case (top_percent - bottom_percent) * max_bytes do
        # value is an edge
        0 -> bytes
        # value is not an edge
        window_bytes -> (bytes - bottom_bytes) / (top_bytes - bottom_bytes) * window_bytes
      end

    round(window_bytes + bottom_percent * max_bytes)
  end

  defp get_window(range_ticks, max_bytes, func) do
    case Enum.find_index(range_ticks, func) do
      # value is between beginning of range and first tick
      0 ->
        {
          {0, 0},
          range_ticks |> Enum.at(0) |> tick_to_bytes()
        }

      # value is between last tick and end of range
      nil ->
        {
          range_ticks |> Enum.at(-1, {0, 0}) |> tick_to_bytes(),
          {max_bytes, 1}
        }

      # value is between two ticks
      index ->
        {
          range_ticks |> Enum.at(index - 1) |> tick_to_bytes(),
          range_ticks |> Enum.at(index) |> tick_to_bytes()
        }
    end
  end

  defp tick_to_bytes({label, percent}) do
    {to_bytes(label), percent}
  end

  @doc """
  Gets the minimum range value based on the ticks. If there is
  no tick at the 0% position, the minimum will be 0.
  """
  def min_range_value([{size, percent} | _]) do
    if percent > 0, do: 0, else: to_bytes(size)
  end

  @doc """
  Gets the maximum range value based on the ticks. If there is no
  tick at the 100% position, the maximum will be calculated based
  on how far the last tick is from the end of the range. If the
  list is empty, the maximum will be 100.
  """
  def max_range_value(range_ticks) when is_list(range_ticks) do
    {size, percent} = List.last(range_ticks)
    size = to_bytes(size)

    if percent < 1, do: round(size / percent), else: size
  end
end
