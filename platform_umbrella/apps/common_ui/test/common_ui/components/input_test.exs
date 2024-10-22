defmodule CommonUI.Components.InputTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Input

  describe "input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input id="foo" name="foo" value="bar" icon={:magnifying_glass} />
      """
    end

    component_snapshot_test "required attr usable through rest" do
      assigns = %{}

      ~H"""
      <.input id="foo" name="foo" value="bar" icon={:magnifying_glass} required />
      """
    end

    component_snapshot_test "with placeholder and error" do
      assigns = %{}

      ~H"""
      <.input id="foo" name="foo" value="bar" placeholder="Foobar" errors={["Oh no"]} />
      """
    end
  end

  describe "textarea input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="textarea" id="foo" name="foo" value="bar" />
      """
    end

    component_snapshot_test "with placeholder and error" do
      assigns = %{}

      ~H"""
      <.input type="textarea" id="foo" name="foo" value="bar" placeholder="Foobar" errors={["Oh no"]} />
      """
    end
  end

  describe "select input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="select" id="foo" name="foo" value="bar" options={[Foo: "foo", Bar: "bar"]} />
      """
    end

    component_snapshot_test "multiple" do
      assigns = %{}

      ~H"""
      <.input type="select" id="foo" name="foo" value="bar" options={[Foo: "foo", Bar: "bar"]} multiple />
      """
    end

    component_snapshot_test "with placeholder and error" do
      assigns = %{}

      ~H"""
      <.input
        type="select"
        id="foo"
        name="foo"
        value="bar"
        placeholder="Foobar"
        options={[Foo: "foo", Bar: "bar"]}
        errors={["Oh no"]}
      />
      """
    end
  end

  describe "multiselect input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input
        type="multiselect"
        id="foo"
        name="foo"
        value={["bar"]}
        options={[%{name: "Foo", value: "foo"}, %{name: "Bar", value: "bar"}]}
      />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input
        type="multiselect"
        id="foo"
        name="foo"
        value={["bar"]}
        options={[%{name: "Foo", value: "foo"}, %{name: "Bar", value: "bar"}]}
        errors={["Oh no"]}
      />
      """
    end
  end

  describe "checkbox input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="checkbox" id="foo" name="foo" checked />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="checkbox" id="foo" name="foo" checked errors={["Oh no"]} />
      """
    end

    component_snapshot_test "disabled" do
      assigns = %{}

      ~H"""
      <.input type="checkbox" id="foo" name="foo" checked disabled />
      """
    end
  end

  describe "radio input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="radio" id="foo" name="foo" value="bar">
        <:option value="foo">Foo</:option>
        <:option value="bar">Bar</:option>
      </.input>
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="radio" id="foo" name="foo" value="bar" errors={["Oh no"]}>
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
      <.input type="switch" id="foo" name="foo" value="bar" checked />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="switch" id="foo" name="foo" value="bar" checked errors={["Oh no"]} />
      """
    end

    component_snapshot_test "with boolean" do
      assigns = %{}

      ~H"""
      <.input type="switch" id="foo" name="foo" value="true" checked />
      """
    end

    component_snapshot_test "disabled with boolean" do
      assigns = %{}

      ~H"""
      <.input type="switch" id="foo" name="foo" value="true" checked disabled />
      """
    end
  end

  describe "range input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="range" id="foo" name="foo" value={5} max={10} />
      """
    end

    component_snapshot_test "with min" do
      assigns = %{}

      ~H"""
      <.input type="range" id="foo" name="foo" value={5} min={2} max={10} />
      """
    end

    component_snapshot_test "with no value" do
      assigns = %{}

      ~H"""
      <.input type="range" id="foo" name="foo" value={5} max={10} show_value={false} />
      """
    end

    component_snapshot_test "with boundaries" do
      assigns = %{}

      ~H"""
      <.input type="range" id="foo" name="foo" value={5} max={10} lower_boundary={2} upper_boundary={8} />
      """
    end

    component_snapshot_test "with ticks" do
      assigns = %{}

      ~H"""
      <.input type="range" id="foo" name="foo" value={5} max={10} ticks={[{"20%", 0.2}, {"80%", 0.8}]} />
      """
    end
  end

  component_snapshot_test "hidden input component" do
    assigns = %{}

    ~H"""
    <.input type="hidden" id="foo" name="foo" value="bar" />
    """
  end

  component_snapshot_test "disabled password component" do
    assigns = %{}

    ~H"""
    <.input
      type="password"
      id="foo"
      name="foo"
      value="somereallylongpasswordthatwedontwanttoshowforsecurity"
      disabled
    />
    """
  end
end
