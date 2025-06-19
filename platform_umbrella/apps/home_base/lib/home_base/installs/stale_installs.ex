defmodule HomeBase.StaleInstalls do
  @moduledoc false
  use HomeBase, :context

  alias CommonCore.Installation
  alias HomeBase.ET.StoredHostReport
  alias HomeBase.ET.StoredUsageReport

  def list_unstarted_installations(hours \\ 6) do
    cutoff = DateTime.add(DateTime.utc_now(), -hours * 3600, :second)

    # List all the installations that have no user
    # no team, there are no StoredUsageReports with the installation_id,
    # there are no StoredHostReports with the installation_id,
    # and the inserted_at is more than `hours` ago.
    Repo.all(
      from(i in Installation,
        as: :installation,
        where: is_nil(i.user_id),
        where: is_nil(i.team_id),
        where: i.inserted_at < ^cutoff,
        where:
          not exists(
            from(
              shr in StoredHostReport,
              where: parent_as(:installation).id == shr.installation_id,
              select: 1
            )
          ),
        where:
          not exists(
            from(
              sur in StoredUsageReport,
              where: parent_as(:installation).id == sur.installation_id,
              select: 1
            )
          )
      )
    )
  end

  def delete_installation!(installation) do
    Repo.delete!(installation)
  end
end
