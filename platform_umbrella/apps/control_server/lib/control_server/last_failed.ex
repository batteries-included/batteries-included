defmodule ControlServer.LastFailed do
  import Ecto.Query

  alias ControlServer.Repo
  alias Oban.Job

  def last_failed do
    query =
      from(job in Job,
        order_by: [desc: job.inserted_at],
        limit: 2,
        where: job.attempt == job.max_attempts
      )

    Repo.all(query)
  end
end
