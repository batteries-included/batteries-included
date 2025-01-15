defmodule CommonCore.Projects.ProjectTest do
  use ExUnit.Case

  import CommonCore.Factory

  alias CommonCore.Projects.Project

  describe "export" do
    test "export/1" do
      assert {:ok, exp} = Project.export(build(:project))
      assert is_binary(exp)
    end
  end
end
