defmodule CommonUI do
  @moduledoc """
  Documentation for `CommonUI`.
  """

  defmacro __using__(_) do
    quote do
      import CommonUI.{Button, LabeledDefiniton, Table, Form, Link, Typogoraphy, DataList}
    end
  end
end
