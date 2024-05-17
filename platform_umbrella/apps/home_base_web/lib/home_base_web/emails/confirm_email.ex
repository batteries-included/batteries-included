defmodule HomeBaseWeb.ConfirmEmail do
  @moduledoc false
  use HomeBaseWeb, :email

  def subject(_email) do
    "Please confirm your email address"
  end

  def text(assigns) do
    ~s"""
    Hi there,

    Please copy the link below into your browser to confirm your email
    address:

    #{assigns.url}
    """
  end

  def html(assigns) do
    ~H"""
    <.email_container>
      <p>Hi there,</p>
      <p>
        Please click on the button below to confirm your email address.
      </p>
      <br />
      <.email_button href={@url}>Confirm my email</.email_button>
    </.email_container>
    """
  end
end
