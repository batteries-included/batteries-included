# WhatsUp

Hello and thank you for your interest in Batteries Included. Here we're building
a down detector web service. In the end it will show what of the configured
websites are UP (responding correctly and quickly enough) or DOWN (erroring,
unexpected response, or too slow)

# Exercise

For this exercise we're going to help make that service. Right now both the
backend and the front end are bare skeleton versions for a coming MVP. Choose
the FrontEnd or the BackEnd or both for a full stack and make some improvements
in the project. Along the way create clean code, that's well designed, modular,
functional, documented well, and testable.

Please use git along the way. Document what you try, what you do, and then what
you end up with.

## Backend

The backend entry point is `WhatsUp.status/0` that method in `lib/whats_up.ex`
doesn't do anything right now. We can build the system that will check all the
sites.

Each site is represented by a row in the database `WhatsUp.Detector.Site` and
accessed through the standard ecto access functions in `WhatsUp.Detector`
located in `lib/whats_up/detector.ex`

Fill in the mechanism to periodically test the site urls and see the result.
Turning the back end into something functional rather than a random number
generator, along with any additions or changes needed.

## Frontend

The main page is very bare bones with horrible usability and no discoverability.
Lets make this whole thing better and easier to use. There are two main routes,
and some components that all need some work.

- `http://localhost:4000/` the main route is a live view implemented by
  `WhatsUpWeb.HomeLive.Home` located at `lib/whats_up_web/live/home.ex` It
  currently simply polls showing two different tables with no sorting,
  filtering, display though, or design.
- `http://localhost:4000/sites` is implemented by the live view
  `WhatsUpWeb.SiteLive.Index` located at
  `lib/whats_up_web/live/site_live/index.ex`
- Components are just the auto generated components from Phoenix live view
  generators.

Possible improvements include:

- Better add/edit flow that's faster and easier to use
- Make the home page more packed with information
- Make the home page more pleasant to see
- Make the components better (That navigation isn't super pretty)

## How To Run

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with
  `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Learn more

- Finch HttpClient: https://github.com/sneako/finch
- Ecto SQL library: https://hexdocs.pm/ecto/Ecto.html
