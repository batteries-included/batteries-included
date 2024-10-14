---
title: 'Heyya Testing Library Reaches Version 1.0.0'
excerpt:
  Heyya testing library reaches version 1.0.0, adding snapshot testing for live
  views in addition to the existing component snapshot testing.
publishDate: 2024-07-30
tags: ['phoenix', 'elixir', 'testing']
image: /public/images/posts/post-15.jpg
draft: false
---

At [Batteries Included](https://www.batteriesincl.com/), we are building a
platform with automation and an easy-to-use UI. Testing is critical to bring
this complex system to life and keep it stable while building. Creating and
maintaining tests can be challenging, especially when the system is complex, and
the UI is in flux.

To help with this, we have been working on a new open-source library for testing
named [Heyya](https://github.com/batteries-included/heyya). Heyya makes it easy
to create and verify snapshots of your Phoenix components, helping to ensure
their correctness and stability. It's a combination of Phoenix's
`Phoenix.LiveViewTest` and `Floki` that was inspired by React snapshot testing,
including Jest. Today's release of 1.0.0 comes with an exciting new feature:
snapshot testing for LiveView tests, not just components.

## New Feature: Snapshot Testing for LiveViews

Heyya has had snapshot testing for components for a while now but with the new
1.0.0 release, we've added snapshot testing for LiveViews. This means you can
now create snapshots of your LiveViews and verify that they render correctly.
This can be especially useful for testing complex LiveViews that have a lot of
moving parts and can be difficult to test manually.

```elixir
defmodule ExampleWeb.MyLiveTest do
  use ExampleWeb.ConnCase

  # Add this to your LiveView tests to
  # get access to our easy to use pipe based testing flow
  #
  # Now this contains snapshot testing too.
  use Heyya.LiveCase

  test "/page1 toggle button render well", %{conn: conn} do
    conn
    |> start(~p"/page1")
    |> assert_matches_snapshot(selector: "#btn", name: "Default Button")
    |> click("#btn")
    |> assert_matches_snapshot(selector: "#btn", name: "After Click")
    |> click("#btn")
    |> assert_matches_snapshot(selector: "#btn", name: "Default Button")
  end
end
```

Now, when running this with:

```bash
mix test
```

The test will start your Phoenix server, navigate the page, click the button,
and then fail. That's because the snapshots don't match. You can then update the
snapshots with:

```bash
HEYYA_OVERRIDE=true mix test
```

That will again start up the Phoenix server, navigate to the page, click the
button, and update the snapshots. The developer can then review the snapshots
and commit them to the repository. This way, you can ensure that your LiveViews
render correctly and catch any regressions that might occur without writing
repetitive tests asserting that the button has the correct text and CSS classes.

## Other Features

Heyya will help with testing more than simply LiveViews. It can help with
stateless components and stateful components, in addition to full-page LiveView
testing. So you can use Heyya to test all of your Phoenix-powered UI.

- Live component testing is provided by
  [`Heyya.ComponentCase`](https://hexdocs.pm/heyya/Heyya.LiveComponentCase.html)
- Stateless component testing is provided by
  [`Heyya.SnapshotCase`](https://hexdocs.pm/heyya/Heyya.SnapshotCase.html)
