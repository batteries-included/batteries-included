defmodule CommonTesting.ComponentSnapshotTest do
  @moduledoc """
  Documentation for `ComponentSnapshotTest`.
  """

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case
      use Snapshy

      import Phoenix.Component, except: [link: 1]
      import Phoenix.LiveViewTest

      import CommonTesting.ComponentSnapshotTest,
        only: [component_snapshot_test: 2, component_snapshot_test: 3]
    end
  end

  defmacro component_snapshot_test(name, do: expr) do
    quote do
      test unquote(name) do
        match_snapshot(rendered_to_string(unquote(expr)))
      end
    end
  end

  defmacro component_snapshot_test(name, context, do: expr) do
    quote do
      test unquote(name), unquote(context) do
        match_snapshot(rendered_to_string(unquote(expr)))
      end
    end
  end
end
