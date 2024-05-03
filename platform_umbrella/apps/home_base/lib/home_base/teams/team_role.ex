defmodule HomeBase.Teams.TeamRole do
  @moduledoc false
  use HomeBase, :schema

  alias HomeBase.Accounts.User
  alias HomeBase.Teams.Team

  schema "teams_roles" do
    field :is_admin, :boolean, default: false
    field :invited_email, :string

    belongs_to :user, User
    belongs_to :team, Team

    timestamps()
  end

  def changeset(team_role, attrs \\ %{}) do
    team_role
    |> cast(attrs, [:is_admin, :invited_email])
    |> validate_required([:is_admin])
    |> validate_email_address(:invited_email)
    |> unique_constraint([:user, :team], name: "teams_roles_user_id_team_id_index", message: "already on team")
    |> unique_constraint([:invited_email, :team],
      name: "teams_roles_invited_email_team_id_index",
      message: "already invited to team"
    )
  end
end
