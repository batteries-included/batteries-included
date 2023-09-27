defmodule CommonCore.Util.Memory do
  @moduledoc false
  @doc """
  Formats bytes into a human-readable string representing the size in TB, GB, MB, KB, or bytes.
  The second argument specifies whether or not to apply smart rounding (eg. 512GB and 1.5TB).

  ## Examples

      iex> Memory.format_bytes(1024)
      "1KB"

      iex> Memory.format_bytes(137438953472, true)
      "128GB"

      iex> Memory.format_bytes(3839143349769, true)
      "3.5TB"
  """
  def format_bytes(bytes, smart_rounding \\ false)

  def format_bytes(nil, _), do: nil

  def format_bytes(bytes, smart_rounding) when is_binary(bytes),
    do: format_bytes(String.to_integer(bytes), smart_rounding)

  def format_bytes(bytes, smart_rounding) when is_integer(bytes) do
    cond do
      bytes >= 1024 * 1024 * 1024 * 1024 ->
        "#{round_bytes(bytes / (1024 * 1024 * 1024 * 1024), smart_rounding, "TB")}TB"

      bytes >= 1024 * 1024 * 1024 ->
        "#{round_bytes(bytes / (1024 * 1024 * 1024), smart_rounding, "GB")}GB"

      bytes >= 1024 * 1024 ->
        "#{round_bytes(bytes / (1024 * 1024), smart_rounding, "MB")}MB"

      bytes >= 1024 ->
        "#{round_bytes(bytes / 1024, smart_rounding, "KB")}KB"

      true ->
        "#{bytes} bytes"
    end
  end

  defp round_bytes(bytes, true, "TB"), do: Float.round(bytes, 1)
  defp round_bytes(bytes, _, _), do: round(bytes)

  @doc """
  Returns a list of tuples of the form {human_readable_label, bytes} for use in select input options.
  """
  def bytes_as_select_options(byte_options) do
    Enum.map(byte_options, fn bytes ->
      {format_bytes(bytes), bytes}
    end)
  end

  @doc """
  Converts gigabytes (GB) to bytes.

  By default, it returns the byte count as an integer.
  If `as_string` is set to true, it will return the byte count as a string.

  ## Params:
    - `gb`: the number of gigabytes to convert.
    - `as_string`: (optional, default false) a boolean to determine if the result should be returned as a string.

  ## Examples

      iex> gb_to_bytes(1)
      1073741824
  """
  def gb_to_bytes(gb), do: round(:math.pow(2, 30) * gb)

  @doc """
  Converts megabytes (MB) to bytes.

  By default, it returns the byte count as an integer.
  If `as_string` is set to true, it will return the byte count as a string.

  ## Params:
    - `mb`: the number of megabytes to convert.
    - `as_string`: (optional, default false) a boolean to determine if the result should be returned as a string.

  ## Examples

      iex> mb_to_bytes(1)
      1048576

      iex> mb_to_bytes(1, true)
      "1048576"
  """
  def mb_to_bytes(mb, as_string \\ false)
  def mb_to_bytes(mb, true), do: mb |> mb_to_bytes() |> Integer.to_string()
  def mb_to_bytes(mb, false), do: round(:math.pow(2, 20) * mb)
end
