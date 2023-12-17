defmodule CommonCore.Util.EctoValidations do
  @moduledoc false

  import Ecto.Changeset

  def downcase_fields(changeset, fields) do
    Enum.reduce(fields, changeset, fn f, change ->
      value = get_field(change, f)
      down = maybe_downcase(value)

      if down != value do
        put_change(changeset, f, down)
      else
        change
      end
    end)
  end

  defp maybe_downcase(value) when is_binary(value) do
    String.downcase(value)
  end

  defp maybe_downcase(value), do: value
end
