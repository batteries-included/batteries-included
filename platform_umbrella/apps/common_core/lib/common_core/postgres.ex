defmodule CommonCore.Postgres do
  @moduledoc false
  import Ecto.Changeset

  def possible_roles do
    ~w(superuser nosuperuser createdb nocreatedb createrole nocreaterole inherit noinherit login nologin replication noreplication bypassrls nobypassrls)
  end

  def validate_pg_rolelist(changeset, field) do
    validate_change(changeset, field, :pg_role, fn _, value ->
      set = MapSet.new(possible_roles())
      is_in_set = fn possible_role -> MapSet.member?(set, possible_role) end

      all_match = Enum.all?(value, is_in_set)

      if all_match do
        []
      else
        failed = Enum.reject(value, is_in_set)
        [{field, {"is invalid role", [validation: :pg_role, failed: failed]}}]
      end
    end)
  end
end
