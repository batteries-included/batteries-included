defmodule CommonUI.Components.PaginationTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Pagination

  describe "pagination component" do
    component_snapshot_test "first page" do
      assigns = %{}

      ~H"""
      <.pagination meta={
        %{
          has_previous_page?: false,
          has_next_page?: true,
          current_offset: 0,
          current_page: 1,
          page_size: 5,
          total_count: 50
        }
      } />
      """
    end

    component_snapshot_test "next page" do
      assigns = %{}

      ~H"""
      <.pagination meta={
        %{
          has_previous_page?: true,
          has_next_page?: true,
          current_offset: 5,
          current_page: 2,
          page_size: 5,
          total_count: 50
        }
      } />
      """
    end

    component_snapshot_test "last page" do
      assigns = %{}

      ~H"""
      <.pagination meta={
        %{
          has_previous_page?: true,
          has_next_page?: false,
          current_offset: 45,
          current_page: 10,
          page_size: 5,
          total_count: 50
        }
      } />
      """
    end
  end
end
