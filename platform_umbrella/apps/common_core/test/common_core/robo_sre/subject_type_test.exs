defmodule CommonCore.RoboSRE.SubjectTypeTest do
  use ExUnit.Case, async: true

  alias CommonCore.RoboSRE.SubjectType

  describe "SubjectType enum" do
    test "casts valid atom values" do
      assert {:ok, :pod} = SubjectType.cast(:pod)
      assert {:ok, :control_server} = SubjectType.cast(:control_server)
      assert {:ok, :service} = SubjectType.cast(:service)
    end

    test "casts valid string values" do
      assert {:ok, :pod} = SubjectType.cast("pod")
      assert {:ok, :control_server} = SubjectType.cast("control_server")
      assert {:ok, :service} = SubjectType.cast("service")
    end

    test "returns error for invalid values" do
      assert :error = SubjectType.cast(:invalid)
      assert :error = SubjectType.cast("invalid")
    end

    test "provides human-readable labels" do
      assert "Pod" = SubjectType.label(:pod)
      assert "Control Server" = SubjectType.label(:control_server)
      assert "Service" = SubjectType.label(:service)
    end

    test "provides options for forms" do
      options = SubjectType.options()
      assert is_list(options)
      assert {"Pod", :pod} in options
      assert {"Service", :service} in options
    end
  end
end
