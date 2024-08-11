defmodule CommonCore.PGUserTest do
  use ExUnit.Case

  alias CommonCore.Postgres.PGUser

  test "keeps provided password" do
    changeset = PGUser.changeset(%PGUser{}, %{username: "user"})

    assert changeset.changes.username == "user"
  end

  test "accepts roles list" do
    changeset = PGUser.changeset(%PGUser{}, %{username: "user", roles: ["role1", "role2"]})

    assert changeset.changes.roles == ["role1", "role2"]
  end

  test "validates required fields" do
    changeset = PGUser.changeset(%PGUser{}, %{})

    refute changeset.valid?

    assert changeset.errors == [username: {"can't be blank", [validation: :required]}]
  end
end
