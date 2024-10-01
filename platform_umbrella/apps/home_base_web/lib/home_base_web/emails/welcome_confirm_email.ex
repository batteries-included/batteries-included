defmodule HomeBaseWeb.WelcomeConfirmEmail do
  @moduledoc false
  use HomeBaseWeb, :email

  def subject(_email) do
    "Please confirm your email address"
  end

  def text(assigns) do
    ~s"""
    Hi there,

    Welcome to Batteries Included! We are so excited to have you here.
    Please copy the link below into your browser to confirm your email
    address:

    #{assigns.url}

    If you have any questions or feedback, please don't hesitate to reply
    to this email. We'd love to hear from you! If you want to read more
    about our vision and roadmap, visit our blog at:

    #{assigns.home_url}/posts

    All the best,
    The Batteries Included Team
    """
  end

  def html(assigns) do
    ~H"""
    <.email_container>
      <p>Hi there,</p>
      <p>
        Welcome to Batteries Included! We are so excited to have you here. Please click on the button below to confirm your email address.
      </p>
      <br />
      <.email_button href={@url}>Confirm my email</.email_button>
      <br />
      <p>
        If you have any questions or feedback, please don't hesitate to reply to this email. We'd love to hear from you! If you want to read more about our vision and roadmap, visit <a
          href={"#{@home_url}/posts"}
          target="_blank"
        >our blog</a>.
      </p>
      <p>All the best,<br />The Batteries Included Team</p>
    </.email_container>
    """
  end
end
