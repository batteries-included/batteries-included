defmodule CommonTesting.ComponentSnapshotTest do
  @moduledoc """
  `ComponentSnapshotTest` allows for fast snapshot
  testing of Phoenix components. Snapshot testing
  components is a fast and easy way to ensure that
  they work and produce what they expected to
  produce without having to hand write
  assertions.


  """

  @doc """
  Wire up the module to prepare for snapshot testing.
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

  @doc """
  A named component snapshot test
  """
  defmacro component_snapshot_test(name, do: expr) do
    quote do
      test unquote(name) do
        match_snapshot(rendered_to_string(unquote(expr)))
      end
    end
  end

  @doc """
  A named component snapshot test, where context is passed through.
  """
  defmacro component_snapshot_test(name, context, do: expr) do
    quote do
      test unquote(name), unquote(context) do
        match_snapshot(rendered_to_string(unquote(expr)))
      end
    end
  end
end
