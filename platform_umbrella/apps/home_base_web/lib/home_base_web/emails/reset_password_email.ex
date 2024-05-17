defmodule HomeBaseWeb.ResetPasswordEmail do
  @moduledoc false
  use HomeBaseWeb, :email

  def subject, do: "Reset your password"

  def text(assigns) do
    ~s"""
    Hi there,

    Sorry to hear you forgot your password! Please copy the link
    below into your browser to reset it. If you didn't request
    this, you can safely ignore this email.

    #{assigns.url}
    """
  end

  def html(assigns) do
    ~H"""
    <.email_container>
      <p>Hi there,</p>
      <p>
        Sorry to hear you forgot your password! Please click on the button below to reset it. If you didn't request this, you can safely ignore this email.
      </p>
      <br />
      <.email_button href={@url}>Reset my password</.email_button>
    </.email_container>
    """
  end
end
