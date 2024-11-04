defmodule CommonCore.URLs do
  @moduledoc false

  @marketing_url "https://batteriesincl.com"
  @github_url "https://github.com/batteries-included/batteries-included"

  def marketing_url, do: @marketing_url
  def docs_url, do: @marketing_url <> "/docs"
  def github_url, do: @github_url
  def github_issues_url, do: @github_url <> "/issues/new"
  def slack_url, do: "https://join.slack.com/t/batteries-included/shared_invite/zt-2qw1pm9pz-egaqvjbMuzKNvCpG1QXXHg"
end
