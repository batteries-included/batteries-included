defmodule ControlServerWeb.ErrorHTML do
  use ControlServerWeb, :html

  import ControlServerWeb.SidebarLayout

  alias CommonCore.Batteries.Catalog

  def render("404.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />

        <title>Page Not Found · Batteries Included</title>

        <link rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"} />
      </head>
      <body class="antialiased text-gray-darkest dark:text-gray-light font-sans font-normal leading-loose">
        <.sidebar_layout main_menu_items={Catalog.groups_for_nav()}>
          <div class="grid grid-cols-1 lg:grid-cols-2 justify-items-center lg:gap-36 h-full">
            <div class="self-end lg:self-center lg:justify-self-end">
              <.logo variant="sad" class="size-96 fill-primary-light dark:fill-primary opacity-75" />
            </div>

            <div class="self-start lg:self-center lg:justify-self-start text-center lg:text-left font-sans font-normal text-gray-darkest dark:text-gray-lightest">
              <h1 class="text-8xl font-extrabold mb-8 leading-none">Oops!</h1>

              <p class="max-w-sm mb-8 leading-normal">
                Error 404. Or in human-talk, we couldn't find the page you were looking for.
              </p>

              <div class="flex gap-4">
                <.button variant="primary" link={~p"/help"}>
                  Get Help
                </.button>

                <.button
                  variant="secondary"
                  link={{:javascript, "history.back()"}}
                  link_type="external"
                >
                  Go Back
                </.button>
              </div>
            </div>
          </div>
        </.sidebar_layout>
      </body>
    </html>
    """
  end

  def render("500.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
        <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no" />

        <title>Internal Server Error · Batteries Included</title>

        <style type="text/css">
          html {
            /* from tailwind preflight */
            line-height: 1.5;
          }

          body {
            /* from tailwind preflight */
            box-sizing: border-box;
            margin: 0;

            -webkit-font-smoothing: antialiased; /* antialiased */
            -moz-osx-font-smoothing: grayscale; /* antialiased */

            display: grid; /* grid */
            grid-template-columns: repeat(1, minmax(0, 1fr)); /* grid-cols-1 */
            justify-items: center; /* justify-items-center */
            min-height: 100vh; /* h-full */
            padding: 3rem; /* p-12 */
            background: linear-gradient(0deg, #fffcfd 0%, #fbf0f9 45%, #fafaff 100%); /* sidebar-background */
            color: #1C1C1E; /* text-gray-darkest */
            font-family: ui-sans-serif, system-ui, sans-serif; /* font-sans */
            font-weight: 400; /* font-normal */
            line-height: 2; /* leading-loose */
          }

          .logo {
            align-self: end; /* self-end */
          }

          .logo svg {
            width: 24rem; /* size-96 */
            height: 24rem; /* size-96 */
            fill: #FFA8CB; /* fill-primary-light */
            opacity: 0.75; /* opacity-75 */
          }

          .wrapper {
            align-self: start; /* self-start */
            text-align: center; /* text-center */
          }

          h1 {
            font-size: 6rem; /* text-8xl */
            font-weight: 800; /* font-extrabold */
            margin-top: 0; /* mt-0 */
            margin-bottom: 2rem; /* mb-8 */
            line-height: 1; /* */
          }

          p {
            max-width: 24rem; /* max-w-sm */
            line-height: 1.5; /* leading-normal */
            margin: 0; /* m-0 */
          }

          p:not(:last-child) {
            margin-bottom: 1rem; /* mb-4 */
          }

          p a {
            display: inline-block; /* inline-block */
            font-weight: 500; /* font-medium */
            color: #FC408B; /* text-primary */
            text-decoration: none; /* no-underline */
          }

          p a:hover {
            color: #DE2E74; /* hover:text-primary-dark */
            text-decoration: underline; /* hover:underline */
          }

          @media (prefers-color-scheme: dark) {
            body {
              background: linear-gradient(0deg, #311520 0%, #181b22 45%, #313145 100%); /* sidebar-background */
              color: #FAFAFA; /* dark:text-gray-lighter */
            }

            .logo svg {
              fill: #FC408B; /* dark:fill-primary */
            }
          }

          @media (min-width: 1024px) {
            body {
              grid-template-columns: repeat(2, minmax(0, 1fr)); /* lg:grid-cols-2 */
              gap: 9rem; /* lg:gap-36 */
            }

            .logo {
              align-self: center; /* lg:self-center */
              justify-self: end; /* lg:justify-self-end */
            }

            .wrapper {
              align-self: center; /* lg:self-center */
              justify-self: start; /* lg:justify-self-start */
              text-align: left; /* lg:text-left */
            }
          }
        </style>
      </head>
      <body>
        <div class="logo">
          <svg viewBox="0 0 146 124">
            <path d="M50.352,123.483c-0,0 -5.715,-5.018 -3.735,-11.215l-0.029,-0.079c16.202,-21.163 46.447,-13.28 53.659,10.591c-20.82,-19.944 -38.062,-20.708 -49.895,0.703Z" />
            <path d="M37.214,39.11l-4.68,0c-11.73,0 -21.32,9.59 -21.32,21.32c-0,11.73 9.6,21.32 21.32,21.32l27.17,0c1.4,0 2.76,-0.14 4.09,-0.4l-0.06,0c7.83,-1.54 14.16,-7.4 16.38,-14.97c-2.83,-1.96 -4.68,-5.23 -4.68,-8.94c-0,-6 4.87,-10.87 10.87,-10.87c6,0 10.87,4.87 10.87,10.87c-0,4.42 -2.64,8.23 -6.44,9.93c-0.05,0.21 -0.09,0.41 -0.14,0.61l0.06,0c-3.42,13.85 -15.98,24.2 -30.84,24.2l-27.38,0c-17.47,0 -31.76,-14.29 -31.76,-31.75c-0,-15.85 11.77,-29.09 27.01,-31.4l-0.07,-0.07c6.75,-30.54 42.83,-37.14 62.33,-15.32c-32.03,-10.9 -50.75,-3.17 -52.73,25.47Zm52.411,13.013l-3.31,3.31l-3.309,-3.31l-2.008,2.008l3.309,3.31l-3.309,3.309l2.008,2.008l3.309,-3.309l3.31,3.309l2.008,-2.008l-3.309,-3.309l3.309,-3.31l-2.008,-2.008Z" />
            <path d="M119.094,36.61c14.48,0.15 26.28,12.04 26.28,26.55c-0,14.61 -11.95,26.56 -26.56,26.56c-10.12,0 -17.43,-2.12 -25.23,-9.31l24.02,0c9.49,0 17.25,-7.76 17.25,-17.25c-0,-9.49 -7.76,-17.25 -17.25,-17.25l-5.27,0c-3.86,-9.35 -13.07,-15.93 -23.81,-15.93c-11.57,0 -21.37,7.64 -24.61,18.14c3.16,1.9 5.27,5.36 5.27,9.32c-0,6 -4.87,10.87 -10.87,10.87c-6,0 -10.87,-4.87 -10.87,-10.87c-0,-4.22 2.4,-7.87 5.91,-9.67c3.63,-16.08 18,-28.09 35.17,-28.09c12.88,0 24.19,6.76 30.56,16.92l0.01,0.01Zm-57.457,15.513l-3.309,3.31l-3.309,-3.31l-2.008,2.008l3.309,3.31l-3.309,3.309l2.008,2.008l3.309,-3.309l3.309,3.309l2.009,-2.008l-3.31,-3.309l3.31,-3.31l-2.009,-2.008Z" />
          </svg>
        </div>

        <div class="wrapper">
          <h1>Oh no!</h1>

          <p>
            Error 500. Or in human-talk, something went wrong on our end. Try refreshing the page or coming back later.
          </p>

          <p>
            Need some help? Check out our <.a
              href="https://www.batteriesincl.com/docs"
              target="_blank"
            >docs</.a>, file an issue on <.a
              href="https://github.com/batteries-included/batteries-included/issues/new"
              target="_blank"
            >
              GitHub
            </.a>, or come visit us in <.a
              href="https://join.slack.com/t/batteries-included/shared_invite/zt-2qw1pm9pz-egaqvjbMuzKNvCpG1QXXHg"
              target="_blank"
            >
              Slack
            </.a>.
          </p>
        </div>
      </body>
    </html>
    """
  end

  # The default is to render a plain text page based on
  # the template name. For example, "404.html" becomes
  # "Not Found".
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
