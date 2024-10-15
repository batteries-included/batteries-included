---
title: 'Heyya Snap It Like A Polaroid'
excerpt:
  Batteries Included has just released a new open-source library for testing
  Phoenix components
publishDate: 2022-12-08
tags: ['phoenix', 'elixir', 'testing']
image: ./covers/post-4.jpg
draft: false
---

Batteries Included has just released a new open-source library for testing
Phoenix components. The library, called
[Heyya](https://github.com/batteries-included/heyya), makes it easy to create
and verify snapshots of your Phoenix components, helping to ensure their
correctness and stability. It's a combination of Phoenix's
[`Phoenix.LiveViewTest`](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html)
and [`Floki`](https://hexdocs.pm/floki/readme.html) that's been inspired by
react snapshot testing, including
[Jest](https://jestjs.io/docs/snapshot-testing)

# Snapshot Testing

Snapshot testing is a powerful tool that can help to ensure the correctness and
stability of your Phoenix LiveView components. It creates a "snapshot" of the
component's rendered output and saves it in a text file. The snapshot is
compared to the latest markup during subsequent tests to ensure it has stayed
the same.

## Stateless

Snapshot testing can benefit functional components in Phoenix LiveView because
these components are typically e straightforward to test than stateful
components. Functional components are pure functions without any internal state
or side effects. This functional purity means they always produce the same
output for a given set of inputs. With snapshot testing, you can create a
snapshot of the rendered output of a functional component and then use that
snapshot to verify that the component continues to produce the same output for
the same inputs. This ensures that the component is correct and stable and can
help to catch any regressions or other issues that might not be immediately
apparent when manually testing the component.

# Initial Example

For this example, let us assume that we are creating a new app and want a
unified header text. So we might make a header module that looks something like
this:

```elixir
defmodule Header do
  use Phoenix.Component

  slot :inner_block, required: true

  def simple(assigns) do
    ~H"""
    <h1>
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end
end

```

We can easily create a test that checks to make sure that `Header.simple/1`
works with the following code:

```elixir
defmodule HeaderTest
  use Heyya

  component_snapshot_test "Header test" do
    # The assigns map contains values that will be accessible in the H sigil
    assigns: %{}

    ~H"""
    <Header.simple>Testing</Header.simple>
    """
  end

end
```

That code is enough to ensure that passing the slot works and produces the
expected result. For so little work with easy maintenance, snapshot testing can
have a great payoff. Under the hood, the return value from this "Header test"
block is getting rendered to a string. Then `Heyya` compare html nodes generated
to the stored html in `test/__snapshots__/**/*.snap`. If this is the first test
run, Snapshy will store the output in files that need to be added to your source
control.

## Code Changes Always

Let us explore that easy maintenance with an example of how snapshot testing,
which might appear brittle and hard to use in a changing code base, still allows
for a fast development pace.

Later, for example, we might change the component to look like the following:

```elixir
  attr :class, :any, default: "text-3xl font-bold tracking-tight text-gray-900"
  slot :inner_block, required: true

  def simple(assigns) do
    ~H"""
    <h1 class={@class}>
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end
```

Notice that we added a default css class that will make the text look nicer.
However, it will also make the previous tests fail with an error. We'll get an
error like this:

```
Generated common_testing app


  1) test Header test (CommonTesting.ComponentSnapshotTestTest)
     test/common_testing/component_snapshot_test.exs:4
     Received value does not match stored snapshot. (__snapshots__/common_testing/component_snapshot_test/test__header_test.snap)
     code:  "Snapshot == Received"
     left:  "<h1>Testing</h1>"
     right: "<h1 class=\"text-3xl font-bold tracking-tight text-gray-900 \">\n  Testing\n</h1>"
     stacktrace:
       (snapshy 0.3.0) lib/snapshy.ex:147: Snapshy.raise_error/3
       (snapshy 0.3.0) lib/snapshy.ex:118: Snapshy.match/2
       test/common_testing/component_snapshot_test.exs:4: (test)


Finished in 0.04 seconds (0.00s async, 0.04s sync)
1 test, 1 failure
```

Rather than writing new assertions that the rendered code contains "text-3xl
font-bold tracking-tight text-gray-900", we can re-run the failing test with a
particular environment variable instead.

```sh
$ HEYYA_OVERRIDE=true mix test

Compiling 1 file (.ex)
S.
Finished in 0.02 seconds (0.00s async, 0.02s sync)
1 test, 0 failures

Randomized with seed 527608
```

That environment variable `HEYYA_OVERRIDE=true` will reset the snapshot, so all
future tests will assert that the component yields the new expected output. It's
also straightforward to add a test to show that setting the class attribute has
the desired effect.

```elixir
defmodule HeaderTest do
  use Heyya

  component_snapshot_test "Header test" do
    assigns: %{}

    ~H"""
    <Header.simple>Testing</Header.simple>
    """
  end

  component_snapshot_test "Header test explicit class" do
    assigns: %{custom_class: "my-class"}

    ~H"""
    <Header.simple class={@custom_class}>Testing with static</Header.simple>
    """
  end
end
```

Run `mix test`, then verify that the new `.snap` file contains the expected
'my-class' and that's it. Creating a test that demonstrates the working parts of
the component is as easy as just using the feature. It's so easy that you'll
have no excuse.

# Where

Check out the documentation website at <https://hexdocs.pm/heyya/readme.html>
and the code on GitHub at <https://github.com/batteries-included/heyya>.

Happy testing!
