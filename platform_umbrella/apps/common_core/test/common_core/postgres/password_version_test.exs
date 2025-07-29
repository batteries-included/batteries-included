defmodule CommonCore.Postgres.PasswordVersionTest do
  use ExUnit.Case

  alias CommonCore.Postgres.PGPasswordVersion

  test "keeps provided password" do
    changeset = PGPasswordVersion.changeset(%PGPasswordVersion{}, %{password: "password"})

    assert changeset.changes.password == "password"
  end

  test "sets a password when not provided" do
    changeset = PGPasswordVersion.changeset(%PGPasswordVersion{}, %{})

    assert changeset.changes.password
  end
end
