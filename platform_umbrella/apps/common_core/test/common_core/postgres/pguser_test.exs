defmodule CommonCore.PGUserTest do
  use ExUnit.Case

  alias CommonCore.Postgres.PGUser

  test "sets random password when not provided" do
    changeset = PGUser.changeset(%PGUser{}, %{username: "user"})

    assert changeset.changes.password != nil
  end

  test "keeps provided password" do
    changeset = PGUser.changeset(%PGUser{}, %{username: "user", password: "password"})

    assert changeset.changes.password == "password"
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
