defmodule CommonCore.Util.Time do
  @moduledoc """
  Utilities relating to date and time.
  """

  @doc """
  Formats an ISO8601 date string according to the provided format string.
  For formatting options: https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html

      iex> Time.format_iso8601_date("2023-08-23T02:36:14Z", "{Mshort} {D}, {h24}:{m}:{s}")
      "Aug 23, 02:36:14"

      iex> Time.format_iso8601("invalid-date", "{Mshort} {D}, {h24}:{m}:{s}")
      ""

  """
  def format_iso8601(iso8601_string, format_string) do
    case DateTime.from_iso8601(iso8601_string) do
      {:ok, datetime, _} ->
        case Timex.format(datetime, format_string) do
          {:ok, formatted_date} -> formatted_date
          _ -> ""
        end

      _ ->
        ""
    end
  end
end
