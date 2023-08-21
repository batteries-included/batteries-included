defmodule CommonUI do
  @moduledoc """
  Documentation for `CommonUI`.
  """

  defmacro __using__(_) do
    quote do
      import CommonUI.Button
      import CommonUI.Card
      import CommonUI.CSSHelpers
      import CommonUI.DataList
      import CommonUI.Flash
      import CommonUI.Form
      import CommonUI.LabeledDefiniton
      import CommonUI.Link
      import CommonUI.Table
      import CommonUI.TextHelpers
      import CommonUI.Typogoraphy
      import CommonUI.VerticalSteps
    end
  end
end
