defmodule HomeBase.Repo.Migrations.AddSoftDelete do
  use Ecto.Migration
  import Ecto.SoftDelete.Migration

  @existing_tables ~w(installations stored_host_reports stored_usage_reports teams teams_roles users)a

  def change do
    Enum.each(@existing_tables, fn table ->
      alter table(table) do
        soft_delete_columns()
      end
    end)
  end
end
