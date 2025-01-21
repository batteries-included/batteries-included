defmodule CommonUI.Components.DataListTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.DataList

  component_snapshot_test "default datalist" do
    assigns = %{}

    ~H"""
    <.data_list>
      <:item title="First">Main Text</:item>
      <:item title="Field Name">More Text</:item>
      <:item title="Views">200</:item>
    </.data_list>
    """
  end

  component_snapshot_test "default datalist with help" do
    assigns = %{}

    ~H"""
    <.data_list id="my-datalist">
      <:item title="Number 1" help="Some text to make this easy">
        Something that needs to be explained
      </:item>
      <:item title="Fact">Not everything needs a help text</:item>
      <:item title="Anohter" hel="More help here">
        it can be up to the developer where to use the help
      </:item>
    </.data_list>
    """
  end

  component_snapshot_test "horizontal-plain datalist" do
    assigns = %{}

    ~H"""
    <.data_list
      variant="horizontal-plain"
      data={[{"First", "Main Text"}, {"Field Name", "More Text"}, {"Views", 200}]}
    />
    """
  end

  component_snapshot_test "horizontal-bolded datalist" do
    assigns = %{}

    ~H"""
    <.data_list
      variant="horizontal-bolded"
      data={[{"First", "Main Text"}, {"Field Name", "More Text"}, {"Views", 200}]}
    />
    """
  end
end
