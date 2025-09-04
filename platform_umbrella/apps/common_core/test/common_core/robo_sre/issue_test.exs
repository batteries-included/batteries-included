defmodule CommonCore.RoboSRE.IssueTest do
  use ExUnit.Case, async: true

  alias CommonCore.RoboSRE.Issue

  @valid_attrs %{
    subject: "cluster1.pod.my-app.container",
    subject_type: :pod,
    issue_type: :pod_crash,
    trigger: :kubernetes_event,
    status: :detected
  }

  @invalid_attrs %{
    subject: "invalid subject",
    subject_type: :invalid,
    issue_type: :invalid,
    trigger: :invalid,
    status: :invalid
  }

  describe "changeset/2" do
    test "valid changeset with required fields" do
      changeset = Issue.changeset(%Issue{}, @valid_attrs)
      assert changeset.valid?
    end

    test "invalid changeset with invalid fields" do
      changeset = Issue.changeset(%Issue{}, @invalid_attrs)
      refute changeset.valid?
    end

    test "requires subject, subject_type, issue_type, trigger, and status" do
      changeset = Issue.changeset(%Issue{}, %{})

      assert changeset.errors[:subject]
      assert changeset.errors[:subject_type]
      assert changeset.errors[:issue_type]
      assert changeset.errors[:trigger]
      # Status has a default value, so it won't be in the errors
      refute changeset.valid?
    end

    test "validates subject format" do
      # Valid formats
      valid_changeset = Issue.changeset(%Issue{}, %{@valid_attrs | subject: "cluster.pod.resource"})
      assert valid_changeset.valid?

      valid_changeset = Issue.changeset(%Issue{}, %{@valid_attrs | subject: "cluster.pod.resource.subresource"})
      assert valid_changeset.valid?

      # Invalid format
      invalid_changeset = Issue.changeset(%Issue{}, %{@valid_attrs | subject: "invalid format"})
      refute invalid_changeset.valid?
      assert invalid_changeset.errors[:subject]
    end

    test "sets resolved_at when status changes to resolved" do
      changeset = Issue.changeset(%Issue{}, %{@valid_attrs | status: :resolved})
      assert changeset.changes[:resolved_at]
    end
  end
end
