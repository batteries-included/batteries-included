defmodule CommonUI do
  @moduledoc """
  CommonUI keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defmacro __using__(_) do
    quote do
      import CommonUI.Button
      import CommonUI.Card
      import CommonUI.Container
      import CommonUI.DataList
      import CommonUI.Flash
      import CommonUI.Form
      import CommonUI.Link
      import CommonUI.Table
      import CommonUI.TextHelpers
      import CommonUI.Tooltip
      import CommonUI.Typography
      import CommonUI.VerticalSteps
    end
  end
end
