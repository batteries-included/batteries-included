defmodule HomeBaseWeb.TeamBootedEmail do
  @moduledoc false
  use HomeBaseWeb, :email

  def subject(%{assigns: assigns}) do
    "You have been removed from #{assigns.team.name}"
  end

  def text(assigns) do
    ~s"""
    Hi there,

    We're just letting you know that you've been removed from the
    *#{assigns.team.name}* team. You can no longer view or manage the
    team's installations.
    """
  end

  def html(assigns) do
    ~H"""
    <.email_container>
      <p>Hi there,</p>
      <p>
        We're just letting you know that you've been removed from the <b>{@team.name}</b>
        team. You can no longer view or manage the team's installations.
      </p>
    </.email_container>
    """
  end
end
