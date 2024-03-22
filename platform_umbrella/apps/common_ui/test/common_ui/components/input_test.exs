defmodule CommonUI.Components.InputTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.Input

  describe "text input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input name="foo" value="bar" label="Foobar" icon={:magnifying_glass} />
      """
    end

    component_snapshot_test "required attr usable through rest" do
      assigns = %{}

      ~H"""
      <.input name="foo" value="bar" label="Foobar" required icon={:magnifying_glass} />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input name="foo" value="bar" placeholder="Foobar" errors={["Oh no"]} />
      """
    end
  end

  describe "textarea component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="textarea" name="foo" value="bar" label="Foobar" />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="textarea" name="foo" value="bar" placeholder="Foobar" errors={["Oh no"]} />
      """
    end
  end

  describe "select component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="select" name="foo" value="bar" label="Foobar" options={[Foo: "foo", Bar: "bar"]} />
      """
    end

    component_snapshot_test "multiple" do
      assigns = %{}

      ~H"""
      <.input
        type="select"
        name="foo"
        value="bar"
        label="Foobar"
        options={[Foo: "foo", Bar: "bar"]}
        multiple
      />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input
        type="select"
        name="foo"
        value="bar"
        placeholder="Foobar"
        note="This is a note"
        options={[Foo: "foo", Bar: "bar"]}
        errors={["Oh no"]}
      />
      """
    end
  end
end
