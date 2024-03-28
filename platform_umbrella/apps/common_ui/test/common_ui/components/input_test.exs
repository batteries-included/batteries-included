defmodule CommonUI.Components.InputTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.Input

  describe "input component" do
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

    component_snapshot_test "with placeholder and error" do
      assigns = %{}

      ~H"""
      <.input name="foo" value="bar" placeholder="Foobar" errors={["Oh no"]} />
      """
    end
  end

  describe "textarea input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="textarea" name="foo" value="bar" label="Foobar" />
      """
    end

    component_snapshot_test "with placeholder and error" do
      assigns = %{}

      ~H"""
      <.input type="textarea" name="foo" value="bar" placeholder="Foobar" errors={["Oh no"]} />
      """
    end
  end

  describe "select input component" do
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

    component_snapshot_test "with placeholder and error" do
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

  describe "checkbox input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="checkbox" name="foo" label="Foobar" checked />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="checkbox" name="foo" label="Foobar" checked errors={["Oh no"]} />
      """
    end
  end

  describe "radio input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="radio" name="foobar" value="foo">
        <:option value="foo">Foo</:option>
        <:option value="bar">Bar</:option>
      </.input>
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="radio" name="foobar" value="foo" errors={["Oh no"]}>
        <:option value="foo">Foo</:option>
        <:option value="bar">Bar</:option>
      </.input>
      """
    end
  end

  describe "switch input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="switch" name="foo" value="bar" label="Foobar" checked />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="switch" name="foo" value="bar" label="Foobar" checked errors={["Oh no"]} />
      """
    end
  end

  component_snapshot_test "hidden input component" do
    assigns = %{}

    ~H"""
    <.input type="hidden" name="foo" value="bar" />
    """
  end
end
