defmodule CommonCore.UsageTest do
  use ExUnit.Case, async: true

  alias CommonCore.Usage

  describe "type/0" do
    test "backing type is string" do
      assert :string == Usage.type()
    end
  end

  describe "cast/1" do
    test "accepts atoms and strings for known usages" do
      assert {:ok, :development} == Usage.cast(:development)
      assert {:ok, :production} == Usage.cast(:production)
      assert {:ok, :development} == Usage.cast("development")
    end

    test "rejects invalid" do
      assert :error == Usage.cast("unicorn")
    end
  end

  test "usages/0 and usage_options/1 behave" do
    usages = Usage.usages()
    assert {"Development", :development} in usages

    # usage_options should return filtered list for non-admins - pass nil role which is not admin
    opts = Usage.options(nil)
    refute Enum.any?(opts, fn {k, _} -> String.starts_with?(k, "Internal") end)
  end
end
