defmodule CommonCore.Teams.Team do
  @moduledoc false

  use CommonCore, {:schema, no_encode: [:users, :roles, :installations]}

  alias CommonCore.Installation
  alias CommonCore.Teams.TeamRole

  @required_fields [:name]

  batt_schema "teams" do
    field :name, :string
    field :op_email, :string

    has_many :roles, TeamRole, on_replace: :delete
    has_many :users, through: [:roles, :user]
    has_many :installations, Installation

    timestamps()
  end

  def changeset(team, attrs \\ %{}) do
    team
    |> CommonCore.Ecto.Schema.schema_changeset(attrs)
    |> cast_assoc(:roles, with: &TeamRole.changeset/2, sort_param: :sort_roles, drop_param: :drop_roles)
    |> validate_length(:name, max: 255)
    |> validate_email_address(:op_email)
    |> validate_team_name()
  end

  # Don't allow the team name to be set to "personal", since
  # that name is used for switching back to a non-team dashboard.
  defp validate_team_name(changeset) do
    validate_change(changeset, :name, fn _, name ->
      if String.downcase(name) == "personal", do: [name: "can't be \"personal\""], else: []
    end)
  end
end
