defmodule HomeBaseWeb.StoredHostReportJSON do
  alias HomeBase.ET.StoredHostReport

  @doc """
  Renders a single stored_host_report.
  """
  def show(%{stored_host_report: stored_host_report}) do
    %{data: data(stored_host_report)}
  end

  defp data(%StoredHostReport{} = stored_host_report) do
    %{
      id: stored_host_report.id,
      report: stored_host_report.report
    }
  end
end
