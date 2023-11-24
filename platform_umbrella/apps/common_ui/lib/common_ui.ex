defmodule CommonUI do
  @moduledoc """
  Documentation for `CommonUI`.
  """

  defmacro __using__(_) do
    quote do
      import CommonUI.Button
      import CommonUI.Card
      import CommonUI.Container
      import CommonUI.DataList
      import CommonUI.Flash
      import CommonUI.Form
      import CommonUI.LabeledDefiniton
      import CommonUI.Link
      import CommonUI.Table
      import CommonUI.TextHelpers
      import CommonUI.Tooltip
      import CommonUI.Typography
      import CommonUI.VerticalSteps
    end
  end
end
