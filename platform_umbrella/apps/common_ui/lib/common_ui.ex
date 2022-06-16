defmodule CommonUI do
  @moduledoc """
  Documentation for `CommonUI`.
  """

  defmacro __using__(_) do
    quote do
      import CommonUI.Button
      import CommonUI.LabeledDefiniton
    end
  end
end
