defmodule CommonUI do
  @moduledoc """
  Documentation for `CommonUI`.
  """

  defmacro __using__(_) do
    quote do
      import CommonUI.{
        Button,
        DataList,
        Flash,
        Form,
        LabeledDefiniton,
        Link,
        Table,
        Typogoraphy
      }
    end
  end
end
