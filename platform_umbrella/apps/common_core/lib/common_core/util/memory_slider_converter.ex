defmodule CommonCore.Util.MemorySliderConverter do
  @moduledoc """
  Converts a slider value to a byte count and vice versa.

  Pairs with an input slider that goes from 1 - 256:

      <PC.input min="1" max="256" step="1" type="range" field={...} />

  Each slider value represents a number of bytes ... so 1 == 128GB and 256 == 4GB. The bytes go up exponentially for each value increment.

  To change the range we'll need to change these module variables.
  """

  @lower_bound_input 1
  @upper_bound_input 256
  # 128 GB in bytes
  @lower_bound_output 128 * :math.pow(1024, 3)
  # 4 TB in bytes
  @upper_bound_output 4 * :math.pow(1024, 4)

  def slider_value_to_bytes(slider_value) do
    exponent = (slider_value - @lower_bound_input) / (@upper_bound_input - @lower_bound_input)
    round(@lower_bound_output * :math.pow(@upper_bound_output / @lower_bound_output, exponent))
  end

  def bytes_to_slider_value(memory_value) do
    log_ratio =
      :math.log(memory_value / @lower_bound_output) /
        :math.log(@upper_bound_output / @lower_bound_output)

    round(@lower_bound_input + (@upper_bound_input - @lower_bound_input) * log_ratio)
  end
end
