defmodule HomeBaseWeb.TeamsController do
  use HomeBaseWeb, :controller

  def switch(conn, %{"id" => "personal"} = params) do
    conn
    |> delete_session(:team_id)
    |> redirect_to_referrer(params)
  end

  def switch(conn, %{"id" => id} = params) do
    # Get team from current session to ensure it exists and belongs to user
    role = Enum.find(conn.assigns.current_user.roles, &(&1.team_id == id))

    conn =
      if role do
        conn
        |> put_session(:team_id, role.team_id)
        # If switching to a newly created team, we should pass the successfully created message
        |> put_flash(:global_success, Map.get(conn.assigns.flash, "global_success", "Switched to #{role.team.name}"))
      else
        delete_session(conn, :team_id)
      end

    redirect_to_referrer(conn, params)
  end

  # Redirects to the url defined in the query string
  defp redirect_to_referrer(conn, %{"redirect_to" => redirect_to}) do
    redirect(conn, to: redirect_to)
  end

  # Redirects to the previous page using the referer header,
  # or goes back home if the referrer can't be determined.
  defp redirect_to_referrer(conn, _params) do
    with [referer] <- get_req_header(conn, "referer"),
         # Avoid infinite redirect loop
         false <- String.equivalent?(referer, current_url(conn)),
         false <- String.equivalent?(referer, current_path(conn)) do
      redirect(conn, external: referer)
    else
      _ -> redirect(conn, to: ~p"/")
    end
  end
end
