defmodule CommonCore.Util.Time do
  @moduledoc """
  Utilities relating to date and time.
  """

  @doc """
  Formats an ISO8601 date string according to the provided format string.
  For formatting options: https://hexdocs.pm/elixir/1.16.2/Calendar.html#strftime/3

      iex> Time.format_iso8601_date("2023-08-23T02:36:14Z", "{Mshort} {D}, {h24}:{m}:{s}")
      "Aug 23, 02:36:14"

      iex> Time.format_iso8601("invalid-date", "{Mshort} {D}, {h24}:{m}:{s}")
      ""

  """
  def format_iso8601(iso8601_string, format_string) do
    case DateTime.from_iso8601(iso8601_string) do
      {:ok, datetime, _} ->
        Calendar.strftime(datetime, format_string)

      _ ->
        ""
    end
  end

  @now_threshold 5
  @minute 60
  @hour 3600
  @day 24 * 3600

  def from_now(now \\ DateTime.utc_now(), later) do
    diff = DateTime.diff(now, later)

    cond do
      diff < 0 -> "in the future"
      diff <= @now_threshold -> "now"
      diff <= @minute -> "#{diff} seconds ago"
      diff <= @hour -> "#{div(diff, 60)} minutes ago"
      diff <= @day -> "#{div(diff, 3600)} hour ago"
      true -> "#{div(diff, 24 * 3600)} day ago"
    end
  end

  def format(datetime) do
    Calendar.strftime(datetime, "%a, %-d %b %Y %X")
  end
end
