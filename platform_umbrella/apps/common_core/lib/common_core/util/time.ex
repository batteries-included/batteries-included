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

  def days_of_week, do: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  def days_of_week_options, do: Enum.map(days_of_week(), &%{name: &1, value: &1})

  def time_options do
    [
      {"12AM", 0},
      {"1AM", 1},
      {"2AM", 2},
      {"3AM", 3},
      {"4AM", 4},
      {"5AM", 5},
      {"6AM", 6},
      {"7AM", 7},
      {"8AM", 8},
      {"9AM", 9},
      {"10AM", 10},
      {"11AM", 11},
      {"12PM", 12},
      {"1PM", 13},
      {"2PM", 14},
      {"3PM", 15},
      {"4PM", 16},
      {"5PM", 17},
      {"6PM", 18},
      {"7PM", 19},
      {"8PM", 20},
      {"9PM", 21},
      {"10PM", 22},
      {"11PM", 23}
    ]
  end
end
