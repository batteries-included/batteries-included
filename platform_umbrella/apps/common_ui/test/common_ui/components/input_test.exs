defmodule CommonUI.Components.InputTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Input

  describe "input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input id="foo" name="foo" value="bar" label="Foobar" icon={:magnifying_glass} />
      """
    end

    component_snapshot_test "required attr usable through rest" do
      assigns = %{}

      ~H"""
      <.input id="foo" name="foo" value="bar" label="Foobar" required icon={:magnifying_glass} />
      """
    end

    component_snapshot_test "with placeholder and error" do
      assigns = %{}

      ~H"""
      <.input id="foo" name="foo" value="bar" placeholder="Foobar" errors={["Oh no"]} />
      """
    end

    component_snapshot_test "with help text" do
      assigns = %{}

      ~H"""
      <.input
        id="foo"
        name="foo"
        value="bar"
        placeholder="Foobar"
        label="Foobar"
        help="Help text"
        errors={["Oh no"]}
      />
      """
    end
  end

  describe "textarea input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="textarea" id="foo" name="foo" value="bar" label="Foobar" />
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
      <.input
        type="select"
        id="foo"
        name="foo"
        value="bar"
        label="Foobar"
        options={[Foo: "foo", Bar: "bar"]}
      />
      """
    end

    component_snapshot_test "multiple" do
      assigns = %{}

      ~H"""
      <.input
        type="select"
        id="foo"
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
        id="foo"
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

  describe "multiselect input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input
        type="multiselect"
        id="foo"
        name="foo"
        value={["bar"]}
        label="Foobar"
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
        label="Foobar"
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
      <.input type="checkbox" id="foo" name="foo" label="Foobar" checked />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="checkbox" id="foo" name="foo" label="Foobar" checked errors={["Oh no"]} />
      """
    end

    component_snapshot_test "disabled" do
      assigns = %{}

      ~H"""
      <.input type="checkbox" id="foo" name="foo" label="Foobar" checked disabled />
      """
    end
  end

  describe "radio input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="radio" id="foo" name="foobar" value="foo">
        <:option value="foo">Foo</:option>
        <:option value="bar">Bar</:option>
      </.input>
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="radio" id="foo" name="foobar" value="foo" errors={["Oh no"]}>
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
      <.input type="switch" id="foo" name="foo" value="bar" label="Foobar" checked />
      """
    end

    component_snapshot_test "with error" do
      assigns = %{}

      ~H"""
      <.input type="switch" id="foo" name="foo" value="bar" label="Foobar" checked errors={["Oh no"]} />
      """
    end

    component_snapshot_test "with boolean" do
      assigns = %{}

      ~H"""
      <.input type="switch" id="foo" name="foo" value="true" label="Foobar" checked />
      """
    end

    component_snapshot_test "disabled with boolean" do
      assigns = %{}

      ~H"""
      <.input type="switch" id="foo" name="foo" value="true" label="Foobar" checked disabled />
      """
    end
  end

  describe "range input component" do
    component_snapshot_test "default" do
      assigns = %{}

      ~H"""
      <.input type="range" id="foo" name="foo" value={5} max={10} label="Foobar" />
      """
    end

    component_snapshot_test "with min" do
      assigns = %{}

      ~H"""
      <.input type="range" id="foo" name="foo" value={5} min={2} max={10} label="Foobar" />
      """
    end

    component_snapshot_test "with no value" do
      assigns = %{}

      ~H"""
      <.input type="range" id="foo" name="foo" value={5} max={10} label="Foobar" show_value={false} />
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
      label="Foobar"
      value="somereallylongpasswordthatwedontwanttoshowforsecurity"
      disabled
    />
    """
  end
end
