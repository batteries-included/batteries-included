defmodule CommonCore.RoboSRE.Issue do
  @moduledoc """
  Schema for RoboSRE issues that tracks detected problems and their remediation.

  ## Subject Format

  The subject field follows a hierarchical format: `cluster.type.resource[.subresource]`

  Examples:
  - `some-cluster-name.pod.battery-istio.ztunnel`
  - `prod-cluster.node.worker-node-1`
  - `staging.volume.data-postgres-0`
  """

  use CommonCore, :schema

  alias CommonCore.RoboSRE.IssueStatus
  alias CommonCore.RoboSRE.IssueType
  alias CommonCore.RoboSRE.SubjectType
  alias CommonCore.RoboSRE.TriggerType

  @derive {
    Flop.Schema,
    filterable: [:status, :issue_type, :subject_type, :trigger],
    sortable: [:subject, :status, :issue_type, :inserted_at, :updated_at],
    default_limit: 20,
    default_order: %{
      order_by: [:updated_at],
      order_directions: [:desc]
    }
  }

  @required_fields ~w(subject subject_type issue_type trigger status)a

  batt_schema "robo_sre_issues" do
    # Subject: hierarchical identifier like "cluster.type.resource[.subresource]"
    field :subject, :string
    field :subject_type, SubjectType
    field :issue_type, IssueType
    field :trigger, TriggerType
    field :trigger_params, :map, default: %{}
    field :status, IssueStatus, default: :detected

    # Self-referencing for parent-child relationships
    belongs_to :parent_issue, __MODULE__, type: CommonCore.Ecto.BatteryUUID
    has_many :child_issues, __MODULE__, foreign_key: :parent_issue_id

    # Handler information
    field :handler, :string
    field :handler_state, :map, default: %{}

    # Tracking fields
    field :resolved_at, :utc_datetime_usec
    field :retry_count, :integer, default: 0
    field :max_retries, :integer, default: 3

    timestamps()
  end

  @doc """
  Changeset for creating/updating issues.
  """
  def changeset(issue, attrs, opts \\ []) do
    issue
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> validate_length(:subject, max: 500)
    |> validate_length(:handler, max: 200)
    |> validate_number(:retry_count, greater_than_or_equal_to: 0)
    |> validate_number(:max_retries, greater_than_or_equal_to: 0)
    |> validate_subject_format()
    |> maybe_set_resolved_at()
    |> validate_parent_not_self()
  end

  defp validate_subject_format(changeset) do
    validate_change(changeset, :subject, fn :subject, subject ->
      #  Validate format of words  - or _ and numbers separated by dots
      if Regex.match?(~r/^(([a-zA-Z0-9_-])+\.)*([a-zA-Z0-9_-])+$/, subject) do
        []
      else
        [subject: "must be in format 'cluster.type.resource' or 'cluster.type.resource.subresource'"]
      end
    end)
  end

  defp maybe_set_resolved_at(changeset) do
    status = get_change(changeset, :status) || get_field(changeset, :status)

    if status == :resolved and is_nil(get_field(changeset, :resolved_at)) do
      put_change(changeset, :resolved_at, DateTime.utc_now())
    else
      changeset
    end
  end

  defp validate_parent_not_self(changeset) do
    issue_id = get_field(changeset, :id)
    parent_id = get_change(changeset, :parent_issue_id)

    if issue_id && parent_id && issue_id == parent_id do
      add_error(changeset, :parent_issue_id, "cannot be the same as the issue itself")
    else
      changeset
    end
  end
end
