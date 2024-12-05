defmodule HomeBaseWeb.TeamInvitedEmail do
  @moduledoc false
  use HomeBaseWeb, :email

  def subject(%{assigns: assigns}) do
    "You have been invited to #{assigns.team.name}"
  end

  def text(assigns) do
    ~s"""
    Hi there,

    You have been invited to the *#{assigns.team.name}* team on
    Batteries Included. Please copy the link below into your browser
    to sign up for an account and get started!

    #{assigns.url}

    If you have any questions or feedback, please don't hesitate to
    reply to this email. We'd love to hear from you.
    """
  end

  def html(assigns) do
    ~H"""
    <.email_container>
      <p>Hi there,</p>
      <p>
        You have been invited to the <b>{@team.name}</b>
        team on Batteries Included. Please click on the button below to sign up for an account and get started!
      </p>
      <br />
      <.email_button href={@url}>Create an account</.email_button>
      <br />
      <p>
        If you have any questions or feedback, please don't hesitate to reply to this email. We'd love to hear from you.
      </p>
    </.email_container>
    """
  end
end
