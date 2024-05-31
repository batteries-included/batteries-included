defmodule CommonCore.Util.MemorySliderConverter do
  @moduledoc false
  alias CommonCore.Util.Memory

  @control_points [
    {1, Memory.to_bytes(128, :MB)},
    {20, Memory.to_bytes(1, :GB)},
    {40, Memory.to_bytes(10, :GB)},
    {60, Memory.to_bytes(128, :GB)},
    {80, Memory.to_bytes(512, :GB)},
    {100, Memory.to_bytes(2048, :GB)},
    {120, Memory.to_bytes(4096, :GB)}
  ]

  def control_points do
    Enum.map(@control_points, &elem(&1, 1))
  end

  def interpolate(x) when x >= 1 and x <= 120 do
    interpolate(x, @control_points)
  end

  defp interpolate(x, [{x1, y1}, {x2, y2} | _rest]) when x >= x1 and x <= x2 do
    round(y1 + (x - x1) * (y2 - y1) / (x2 - x1))
  end

  defp interpolate(x, [_ | rest]) do
    interpolate(x, rest)
  end

  def generate_array do
    Enum.map(1..120, &interpolate(&1))
  end

  def slider_value_to_bytes(slider_value) do
    interpolated_array = generate_array()
    Enum.at(interpolated_array, slider_value - 1)
  end

  def bytes_to_slider_value(bytes) do
    interpolated_array = generate_array()

    {_, index} =
      interpolated_array
      |> Enum.with_index()
      |> Enum.min_by(fn {value, _index} -> abs(value - bytes) end)

    index + 1
  end
end
