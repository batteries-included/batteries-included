defmodule HomeBaseWeb.StoredUsageReportJSON do
  alias HomeBase.ET.StoredUsageReport

  @doc """
  Renders a single stored_usage_report.
  """
  def show(%{stored_usage_report: stored_usage_report}) do
    %{data: data(stored_usage_report)}
  end

  defp data(%StoredUsageReport{} = stored_usage_report) do
    %{
      id: stored_usage_report.id,
      report: stored_usage_report.report
    }
  end
end
