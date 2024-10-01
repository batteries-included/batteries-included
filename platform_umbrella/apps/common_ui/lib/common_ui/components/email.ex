defmodule CommonUI.Components.Email do
  @moduledoc false

  use CommonUI, :component

  slot :inner_block, required: true

  def email_container(assigns) do
    ~H"""
    <table role="presentation" border="0" cellpadding="0" cellspacing="0" class="main">
      <tr>
        <td class="wrapper">
          <%= render_slot(@inner_block) %>
        </td>
      </tr>
    </table>
    """
  end

  attr :center, :boolean, default: true
  attr :href, :string, required: true
  slot :inner_block, required: true

  def email_button(assigns) do
    ~H"""
    <table
      role="presentation"
      border="0"
      cellpadding="0"
      cellspacing="0"
      class={["btn btn-primary", @center && "center"]}
    >
      <tbody>
        <tr>
          <td align={if @center, do: "center", else: "left"}>
            <table role="presentation" border="0" cellpadding="0" cellspacing="0">
              <tbody>
                <tr>
                  <td>
                    <a href={@href} target="_blank"><%= render_slot(@inner_block) %></a>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  ## Layouts

  def email_text_layout(assigns) do
    ~s"""
    #{if assigns[:preheader], do: "#{assigns.preheader}\n\n---\n\n"}#{assigns.inner_content}
    #{if assigns[:street_address], do: "---\n\n#{assigns.street_address}\n\n"}
    """
  end

  def email_html_layout(assigns) do
    ~H"""
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <meta name="x-apple-disable-message-reformatting" />

        <title :if={assigns[:subject]}><%= @subject %></title>

        <style media="all" type="text/css">
          /* GLOBAL RESETS */

          body {
            font-family: Helvetica, sans-serif;
            -webkit-font-smoothing: antialiased;
            font-size: 16px;
            line-height: 1.3;
            -ms-text-size-adjust: 100%;
            -webkit-text-size-adjust: 100%;
          }

          table {
            border-collapse: separate;
            mso-table-lspace: 0pt;
            mso-table-rspace: 0pt;
            width: 100%;
          }

          table td {
            font-family: Helvetica, sans-serif;
            font-size: 16px;
            vertical-align: top;
          }

          /* BODY & CONTAINER */

          body {
            background-color: #fffcfd;
            background: linear-gradient(0deg, #fffcfd 0%, #fbf0f9 45%, #fafaff 100%);
            margin: 0;
            padding: 0;
          }

          .body {
            background-color: #fffcfd;
            background: linear-gradient(0deg, #fffcfd 0%, #fbf0f9 45%, #fafaff 100%);
            width: 100%;
            min-height: 100%;
          }

          .container {
            margin: 0 auto !important;
            padding: 0;
            padding-top: 24px;
            width: 560px;
            max-width: 560px;
          }

          .content {
            box-sizing: border-box;
            display: block;
            margin: 0 auto;
            max-width: 560px;
            padding: 0;
          }

          /* HEADER, FOOTER, MAIN */

          .logo {
            width: 100%;
            max-width: 100px;
          }

          .main {
            background: #ffffff;
            border: 1px solid #dadada;
            border-radius: 16px;
            width: 100%;
          }

          .wrapper {
            box-sizing: border-box;
            padding: 24px;
          }

          .header {
            clear: both;
            padding-top: 24px;
            padding-bottom: 24px;
            text-align: center;
            width: 100%;
          }

          .header td {
            text-align: center;
          }

          .footer {
            clear: both;
            padding-top: 24px;
            padding-bottom: 24px;
            text-align: center;
            width: 100%;
          }

          .footer td,
          .footer p,
          .footer span,
          .footer a {
            color: #999a9f;
            font-size: 16px;
            text-align: center;
          }

          /* TYPOGRAPHY */

          p {
            font-family: Helvetica, sans-serif;
            font-size: 16px;
            font-weight: normal;
            line-height: 1.4;
            margin: 0;
            margin-bottom: 16px;
          }

          a {
            color: #fc408b;
            text-decoration: underline;
            font-weight: 600;
          }

          /* BUTTONS */

          .btn {
            box-sizing: border-box;
            min-width: 100% !important;
            width: 100%;
          }

          .btn > tbody > tr > td {
            padding-bottom: 16px;
          }

          .btn table {
            width: auto;
          }

          .btn table td {
            background-color: #ffffff;
            border-radius: 4px;
            text-align: center;
          }

          .btn a {
            background-color: #ffffff;
            border: solid 2px #fc408b;
            border-radius: 4px;
            box-sizing: border-box;
            color: #fc408b;
            cursor: pointer;
            display: inline-block;
            font-size: 16px;
            font-weight: bold;
            margin: 0;
            padding: 12px 24px;
            text-decoration: none;
          }

          .btn-primary table td {
            background-color: #fc408b;
          }

          .btn-primary a {
            background-color: #fc408b;
            border-color: #fc408b;
            color: #ffffff;
          }

          @media all {
            .btn-primary table td:hover {
              background-color: #ffa8cb !important;
            }
            .btn-primary a:hover {
              background-color: #ffa8cb !important;
              border-color: #ffa8cb !important;
            }
          }

          /* OTHER STYLES THAT MIGHT BE USEFUL */

          .center {
            text-align: center;
          }

          .preheader {
            color: transparent;
            display: none;
            height: 0;
            max-height: 0;
            max-width: 0;
            opacity: 0;
            overflow: hidden;
            mso-hide: all;
            visibility: hidden;
            width: 0;
          }

          /* RESPONSIVE AND MOBILE FRIENDLY STYLES */

          @media only screen and (max-width: 640px) {
            .main p,
            .main td,
            .main span {
              font-size: 16px !important;
            }
            .content {
              padding: 0 !important;
            }
            .container {
              padding: 0 !important;
              padding-top: 8px !important;
              width: 100% !important;
            }
            .main {
              border-left-width: 0 !important;
              border-radius: 0 !important;
              border-right-width: 0 !important;
            }
            .btn table {
              max-width: 100% !important;
              width: 100% !important;
            }
            .btn a {
              font-size: 16px !important;
              max-width: 100% !important;
              width: 100% !important;
            }
          }

          /* PRESERVE THESE STYLES IN THE HEAD */

          @media all {
            .ExternalClass {
              width: 100%;
            }
            .ExternalClass,
            .ExternalClass p,
            .ExternalClass span,
            .ExternalClass font,
            .ExternalClass td,
            .ExternalClass div {
              line-height: 100%;
            }
            .apple-link a {
              color: inherit !important;
              font-family: inherit !important;
              font-size: inherit !important;
              font-weight: inherit !important;
              line-height: inherit !important;
              text-decoration: none !important;
            }
            #MessageViewBody a {
              color: inherit;
              text-decoration: none;
              font-size: inherit;
              font-family: inherit;
              font-weight: inherit;
              line-height: inherit;
            }
          }
        </style>
      </head>
      <body>
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" class="body">
          <tr>
            <td class="container">
              <div class="content">
                <span :if={assigns[:preheader]} class="preheader">
                  <%= @preheader %>
                </span>

                <div class="header">
                  <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                    <tr>
                      <td class="logo">
                        <a href={@home_url}>
                          <img
                            width="100"
                            src={URI.merge(@home_url, "/images/emails/logo.png") |> to_string()}
                          />
                        </a>
                      </td>
                    </tr>
                  </table>
                </div>

                <%= @inner_content %>

                <div :if={assigns[:street_address]} class="footer">
                  <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                    <tr>
                      <td class="content-block">
                        <span class="apple-link">
                          <%= @street_address %>
                        </span>
                      </td>
                    </tr>
                  </table>
                </div>
              </div>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
  end
end
