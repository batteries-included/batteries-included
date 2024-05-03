defmodule HomeBase.Teams.Team do
  @moduledoc false
  use HomeBase, :schema

  alias HomeBase.Teams.TeamRole

  schema "teams" do
    field :name, :string
    field :op_email, :string

    has_many :roles, TeamRole
    has_many :users, through: [:roles, :team]

    timestamps()
  end

  def changeset(team, attrs \\ %{}) do
    team
    |> cast(attrs, [:name, :op_email])
    |> validate_required([:name])
    |> validate_length(:name, max: 255)
    |> validate_email_address(:op_email)
    |> validate_team_name()
  end

  # Don't allow the team name to be set to "personal", since
  # that name is used for switching back to a non-team dashboard.
  defp validate_team_name(changeset) do
    validate_change(changeset, :name, fn _, name ->
      if String.downcase(name) == "personal", do: [name: "cannot be \"personal\""], else: []
    end)
  end
end
