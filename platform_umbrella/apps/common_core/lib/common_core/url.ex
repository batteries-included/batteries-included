defmodule CommonCore.URL do
  @moduledoc false

  @marketing_url Application.compile_env!(:common_core, :marketing_url)

  def marketing_url, do: @marketing_url
  def docs_url, do: @marketing_url <> "/docs"
  def github_url, do: "https://github.com/batteries-included/batteries-included"
  def github_issues_url, do: "https://github.com/batteries-included/batteries-included/issues/new"
  def slack_url, do: "https://join.slack.com/t/batteries-included/shared_invite/zt-2qw1pm9pz-egaqvjbMuzKNvCpG1QXXHg"
end
