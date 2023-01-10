defmodule CommonCore.Postgres do
  import Ecto.Changeset

  def possible_roles do
    ~w( superuser nosuperuser createdb nocreatedb createrole nocreaterole inherit noinherit login nologin replication noreplication bypassrls nobypassrls )
  end

  def validate_pg_rolelist(changeset, field) do
    validate_change(changeset, field, :pg_role, fn _, value ->
      set = MapSet.new(possible_roles())

      all_match = Enum.all?(value, fn possible_role -> MapSet.member?(set, possible_role) end)

      if all_match do
        []
      else
        failed = Enum.reject(value, fn possible_role -> MapSet.member?(set, possible_role) end)
        [{field, {"is invalid role", [validation: :pg_role, failed: failed]}}]
      end
    end)
  end
end
