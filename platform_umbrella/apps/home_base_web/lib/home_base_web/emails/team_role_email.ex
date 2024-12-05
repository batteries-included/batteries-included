defmodule HomeBaseWeb.TeamRoleEmail do
  @moduledoc false
  use HomeBaseWeb, :email

  def subject(%{assigns: assigns}) do
    "You have been added to #{assigns.team.name}"
  end

  def text(assigns) do
    ~s"""
    Hi there,

    We're just letting you know that you've been added to the
    *#{assigns.team.name}* team. You can now view and manage your
    team's installations:

    #{assigns.url}
    """
  end

  def html(assigns) do
    ~H"""
    <.email_container>
      <p>Hi there,</p>
      <p>
        We're just letting you know that you've been added to the <b>{@team.name}</b>
        team. You can now view and manage your team's installations.
      </p>
      <br />
      <.email_button href={@url}>View installations</.email_button>
    </.email_container>
    """
  end
end
