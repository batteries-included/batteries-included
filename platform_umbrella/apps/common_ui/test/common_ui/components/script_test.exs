defmodule CommonUI.Components.ScriptTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Script

  component_snapshot_test "default script component" do
    assigns = %{}

    ~H"""
    <.script id="foobar" src="https://install.example.com/8ej3l" />
    """
  end

  component_snapshot_test "script with template component" do
    assigns = %{}

    ~H"""
    <.script id="foobar" src="https://install.example.com/8ej3l" template="wget @src" />
    """
  end
end
