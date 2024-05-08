defmodule CommonCore.Resources.Quantity do
  @moduledoc """
  Provides functions for parsing Kubernetes resource quantities.
  """

  @base_1024_exponents %{
    "Ki" => 1,
    "Mi" => 2,
    "Gi" => 3,
    "Ti" => 4,
    "Pi" => 5,
    "Ei" => 6
  }

  @base_1000_expontents %{
    "n" => -3,
    "u" => -2,
    "m" => -1,
    "" => 0,
    "k" => 1,
    "M" => 2,
    "G" => 3,
    "T" => 4,
    "P" => 5,
    "E" => 6
  }

  @find_unit_regex ~r/(\d+)(\w+)?/

  @doc """
  base1024: Ki | Mi | Gi | Ti | Pi | Ei
  base1000: n | u | m | "" | k | M | G | T | P | E
  See https://github.com/kubernetes/apimachinery/blob/master/pkg/api/resource/quantity.go
  """
  def parse_quantity(value) do
    case Regex.run(@find_unit_regex, value) do
      [_, number] ->
        String.to_integer(number)

      [_, number, unit] ->
        number = String.to_integer(number)

        if String.ends_with?(unit, "i") do
          base_1024_exponent = Map.get(@base_1024_exponents, unit)
          number * :math.pow(1024, base_1024_exponent)
        else
          base_1000_exponent = Map.get(@base_1000_expontents, unit)
          number * :math.pow(1000, base_1000_exponent)
        end
    end
  end
end
