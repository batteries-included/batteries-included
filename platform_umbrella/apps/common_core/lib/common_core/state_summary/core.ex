defmodule CommonCore.StateSummary.Core do
  @moduledoc false
  alias CommonCore.StateSummary

  def get_battery(%StateSummary{} = summary, type) do
    Enum.find(summary.batteries, &(&1.type == type))
  end
end
