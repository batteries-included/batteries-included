defmodule CommonCore.Batteries.RoboSREConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  @required_fields ~w()a

  batt_polymorphic_schema type: :robo_sre do
    # Global configuration options for RoboSRE system
    defaultable_field :enabled, :boolean, default: true
    defaultable_field :default_analysis_delay_ms, :integer, default: 200
    defaultable_field :max_concurrent_issues, :integer, default: 50
    defaultable_field :issue_timeout_minutes, :integer, default: 60
    defaultable_field :cleanup_resolved_issues_after_hours, :integer, default: 24
  end
end
