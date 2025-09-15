defmodule CommonCore.RoboSRE.IssueStatusTest do
  use ExUnit.Case, async: true

  alias CommonCore.RoboSRE.IssueStatus

  describe "options/0" do
    test "returns all status options with labels and atoms" do
      options = IssueStatus.options()

      assert length(options) == 7

      expected_options = [
        {"Detected", :detected},
        {"Analyzing", :analyzing},
        {"Planning", :planning},
        {"Remediating", :remediating},
        {"Verifying", :verifying},
        {"Resolved", :resolved},
        {"Failed", :failed}
      ]

      assert options == expected_options
    end
  end

  describe "label/1" do
    test "returns correct labels for all valid statuses" do
      assert IssueStatus.label(:detected) == "Detected"
      assert IssueStatus.label(:analyzing) == "Analyzing"
      assert IssueStatus.label(:planning) == "Planning"
      assert IssueStatus.label(:remediating) == "Remediating"
      assert IssueStatus.label(:verifying) == "Verifying"
      assert IssueStatus.label(:resolved) == "Resolved"
      assert IssueStatus.label(:failed) == "Failed"
    end

    test "capitalizes unknown status atoms" do
      assert IssueStatus.label(:unknown) == "Unknown"
      assert IssueStatus.label(:custom_status) == "Custom_status"
    end
  end

  describe "open_statuses/0" do
    test "returns only non-terminal statuses" do
      open_statuses = IssueStatus.open_statuses()

      expected_open = [:detected, :analyzing, :planning, :remediating, :verifying]
      assert open_statuses == expected_open
      assert length(open_statuses) == 5

      # Verify terminal statuses are not included
      refute :resolved in open_statuses
      refute :failed in open_statuses
    end
  end

  describe "enum behavior" do
    test "can cast valid atoms" do
      assert {:ok, :detected} = IssueStatus.cast(:detected)
      assert {:ok, :analyzing} = IssueStatus.cast(:analyzing)
      assert {:ok, :resolved} = IssueStatus.cast(:resolved)
    end

    test "can cast valid strings" do
      assert {:ok, :detected} = IssueStatus.cast("detected")
      assert {:ok, :analyzing} = IssueStatus.cast("analyzing")
      assert {:ok, :resolved} = IssueStatus.cast("resolved")
    end

    test "rejects invalid values" do
      assert :error = IssueStatus.cast(:invalid)
      assert :error = IssueStatus.cast("invalid")
      assert :error = IssueStatus.cast(123)
    end

    test "can dump valid atoms" do
      assert {:ok, "detected"} = IssueStatus.dump(:detected)
      assert {:ok, "analyzing"} = IssueStatus.dump(:analyzing)
      assert {:ok, "resolved"} = IssueStatus.dump(:resolved)
    end

    test "can load valid strings" do
      assert {:ok, :detected} = IssueStatus.load("detected")
      assert {:ok, :analyzing} = IssueStatus.load("analyzing")
      assert {:ok, :resolved} = IssueStatus.load("resolved")
    end
  end
end
