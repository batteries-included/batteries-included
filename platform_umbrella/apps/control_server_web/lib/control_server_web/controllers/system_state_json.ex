defmodule ControlServerWeb.SystemStateJSON do
  @doc """
  Renders a full snapshot
  """
  def index(%{summary: summary}) do
    %{data: summary}
  end
end
