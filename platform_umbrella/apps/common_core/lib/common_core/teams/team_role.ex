defmodule CommonCore.Teams.TeamRole do
  @moduledoc false

  use CommonCore, :schema

  alias CommonCore.Accounts.User
  alias CommonCore.Teams.Team

  @required_fields [:is_admin]

  batt_schema "teams_roles" do
    field :is_admin, :boolean, default: false
    field :invited_email, :string

    belongs_to :user, User
    belongs_to :team, Team

    timestamps()
  end

  def changeset(team_role, attrs \\ %{}, opts \\ []) do
    team_role
    |> CommonCore.Ecto.Schema.schema_changeset(attrs, opts)
    |> validate_email_address(:invited_email)
    |> unique_constraint([:user, :team],
      name: "teams_roles_user_id_team_id_index",
      message: "already on team",
      error_key: :invited_email
    )
    |> unique_constraint([:invited_email, :team],
      name: "teams_roles_invited_email_team_id_index",
      message: "already invited to team"
    )
  end
end
