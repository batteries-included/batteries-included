defmodule CommonCore.RoboSRE.SubjectTypeTest do
  use ExUnit.Case, async: true

  alias CommonCore.RoboSRE.SubjectType

  describe "SubjectType enum" do
    test "casts valid atom values" do
      assert {:ok, :control_server} = SubjectType.cast(:control_server)
      assert {:ok, :cluster_resource} = SubjectType.cast(:cluster_resource)
    end

    test "casts valid string values" do
      assert {:ok, :control_server} = SubjectType.cast("control_server")
      assert {:ok, :cluster_resource} = SubjectType.cast("cluster_resource")
    end

    test "returns error for invalid values" do
      assert :error = SubjectType.cast(:invalid)
      assert :error = SubjectType.cast("invalid")
    end

    test "provides human-readable labels" do
      assert "Control Server" = SubjectType.label(:control_server)
      assert "Cluster Resource" = SubjectType.label(:cluster_resource)
    end

    test "provides options for forms" do
      options = SubjectType.options()
      assert is_list(options)
      assert {"Control Server", :control_server} in options
      assert {"Cluster Resource", :cluster_resource} in options
    end
  end
end
