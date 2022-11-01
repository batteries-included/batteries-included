defmodule KubeServices.Usage.RestClient do
  @moduledoc """
  The HTTP rest client to report to HomeBase. It doesn't depend on HomeBase or on ControlServer.
  """
  require Logger

  @middleware [
    Tesla.Middleware.JSON,
    Tesla.Middleware.Logger
  ]

  @spec report_usage(binary | Tesla.Client.t(), any) :: {:error, any} | {:ok, Tesla.Env.t()}
  def report_usage(client, usage_report) do
    Tesla.post(client, "/usage_reports/", %{"usage_report" => usage_report})
  end

  @doc """
  Create a new rest based client from a Tesla.client http connection pool

  ## Examples

    iex> HomeBaseClient.RestClient.client("https://home.batteryincl.com")

  """
  def client(base_url \\ "http://localhost:4900/api/") do
    middleware =
      [
        {Tesla.Middleware.BaseUrl, base_url}
      ] ++ @middleware

    Tesla.client(middleware)
  end
end
