defmodule CommonUI do
  @moduledoc """
  Documentation for `CommonUI`.
  """

  defmacro __using__(_) do
    quote do
      import CommonUI.{
        Button,
        Card,
        DataList,
        Flash,
        Form,
        LabeledDefiniton,
        Link,
        Table,
        Typogoraphy,
        VerticalSteps
      }

      import CommonUI.CSSHelpers
      import CommonUI.TextHelpers
    end
  end
end
