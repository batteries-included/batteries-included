---
title: Tips for writing integration tests
description:
  Tips and tricks for working with Wallaby and our integration test suite.
tags: ['code', 'integration', 'testing', 'internal']
category: development
draft: false
---

We use [Wallaby](https://github.com/elixir-wallaby/wallaby) for our integration
testing and have a dedicated Elixir "app" - `Verify` - for running our
end-to-end integration tests.

# Running tests

We use `chromedriver` and `chrome`/`chromium` as the test runner so be sure to
have those installed locally.

```bash
# set version override to specify the version to test against
# container images have to exist for the version specified
export VERSION_OVERRIDE=latest

# run 'em all
bix ex int-test

# alternatively, run a single test
bix ex int-test test/traditional_test.exs

# run tests with additional logging
TEST_LOG_LEVEL=debug bix ex int-test
```

# Writing tests

## General

- Familiarize yourself with the `Wallaby` API. The
  [docs](https://hexdocs.pm/wallaby/readme.html) are a great place to start.
- Familiarize yourself with the helpers we've created - `Verify.TestCase` and
  `Verify.TestCase.Helpers`.
- Check out the existing tests. They aren't perfect but are a good start.

## Tips

### Increase the log level

Typically we hide logs during testing but we have an escape hatch via
`TEST_LOG_LEVEL`.

```bash
TEST_LOG_LEVEL=debug bix ex int-test
```

### Run the tests with a real window (i.e. not headless)

We'll likely add more robust support for this in the future, but for now it can
be helpful to set it up so that the tests run in a window that you can see. This
makes the test iteration cycle **much** faster.

If you'd like all sessions to have a visible window, it's sufficient to just
comment out the `--headless` chrome arg in `Verify.TestCase.start_session/0`.

For additional control, you can change `start_session/0` to have additional args
to pass to the chrome args with a default of `["--headless"]` and then you can
override e.g. the session that is started for the actual tests and not for the
session started for installing batteries.

<details><summary>Example Diff</summary>
<p>

```diff
diff --git a/platform_umbrella/apps/verify/test/support/test_case.ex b/platform_umbrella/apps/verify/test/support/test_case.ex
index 97dcb22f2..957c79ec4 100644
--- a/platform_umbrella/apps/verify/test/support/test_case.ex
+++ b/platform_umbrella/apps/verify/test/support/test_case.ex
@@ -87,8 +87,8 @@ defmodule Verify.TestCase do
     end)
   end

-  @spec start_session() :: {:ok, Wallaby.Session.t()} | {:error, Wallaby.reason()}
-  def start_session do
+  @spec start_session(list()) :: {:ok, Wallaby.Session.t()} | {:error, Wallaby.reason()}
+  def start_session(extra_args \\ ["--headless"]) do
     Wallaby.start_session(
       max_wait_time: 60_000,
       capabilities: %{
@@ -96,29 +96,30 @@ defmodule Verify.TestCase do
         javascriptEnabled: true,
         loadImages: true,
         chromeOptions: %{
-          args: [
-            # Lets act like the world is run on macbooks that
-            # all of sillion valley uses
-            #
-            # Fix this at some point
-            "window-size=1920,1080",
-            # We don't want to see the browser
-            "--headless",
-            "--fullscreen",
-            # Incognito mode means no caching for real
-            # Unfortunately, chrome doesn't allow http requests at all incognito
-            # "--incognito",
-            # Seems to be better for stability
-            "--no-sandbox",
-            # Yeah this will run in CI
-            "--disable-gpu",
-            # Please google go away
-            "--disable-extensions",
-            "--disable-login-animations",
-            "--no-default-browser-check",
-            "--no-first-run",
-            "--ignore-certificate-errors"
-          ]
+          args:
+            [
+              # Lets act like the world is run on macbooks that
+              # all of sillion valley uses
+              #
+              # Fix this at some point
+              "window-size=1920,1080",
+              # We don't want to see the browser
+              # "--headless",
+              "--fullscreen",
+              # Incognito mode means no caching for real
+              # Unfortunately, chrome doesn't allow http requests at all incognito
+              # "--incognito",
+              # Seems to be better for stability
+              "--no-sandbox",
+              # Yeah this will run in CI
+              "--disable-gpu",
+              # Please google go away
+              "--disable-extensions",
+              "--disable-login-animations",
+              "--no-default-browser-check",
+              "--no-first-run",
+              "--ignore-certificate-errors"
+            ] ++ extra_args
         }
       }
     )
```

</p>
</details>
<br>

### Don't tear down the cluster

A majority of the time is spin spinning up the cluster. For rapid iteration,
it's sufficient to comment out the teardown code in `Verify.KindInstallWorker`.
This can cause issues so don't forget to put it back and test on new clusters
before creating a PR.

<details><summary>Example Diff</summary>
<p>

```diff
diff --git a/platform_umbrella/apps/verify/lib/verify/kind_install_worker.ex b/platform_umbrella/apps/verify/lib/verify/kind_install_worker.ex
index e6da02ce1..5d51c5d48 100644
--- a/platform_umbrella/apps/verify/lib/verify/kind_install_worker.ex
+++ b/platform_umbrella/apps/verify/lib/verify/kind_install_worker.ex
@@ -81,7 +81,8 @@ defmodule Verify.KindInstallWorker do

   defp do_stop_all(%{started: started} = state) do
     Enum.each(started, fn {_, path} ->
-      :ok = do_stop(state.bi_binary, path)
+      # :ok = do_stop(state.bi_binary, path)
+      :ok
     end)

     {:reply, :ok, %{state | started: %{}}}
```

</p>
</details>
<br>

### Run Wallaby interactively

If you're not running the sessions headless, it can be helpful to rapidly
iterate on a query by using wallaby from `iex`. From the `verify` application
directory, start `iex` in the test environment, and start wallaby. Then you can
control the browser via wallaby and execute queries as they are executed during
testing. You can manual start the `int-test` cluster or, if you're not having it
tear down, use the existing test cluster. See the example session below.

<details><summary>Example Session</summary>
<p>

```bash
cd platform_umbrella/apps/verify
MIX_ENV=test iex -S mix
Erlang/OTP 27 [erts-15.2.5] [source] [64-bit] [smp:16:16] [ds:16:16:10] [async-threads:1] [jit:ns]

Compiling 1 file (.ex)
Generated verify app
Interactive Elixir (1.18.3) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> Application.ensure_all_started(:wallaby)
{:ok, [:httpoison, :web_driver_client, :wallaby]}
iex(2)> import Wallaby.Browser
Wallaby.Browser
iex(3)> alias Wallaby.Query
Wallaby.Query
iex(4)> import Verify.TestCase.Helpers
Verify.TestCase.Helpers
iex(5)> {:ok, session} = Verify.TestCase.start_session
{:ok,
 %Wallaby.Session{
   id: "33d227e82066ba8f5c47b3673b3e5dad",
   url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
   session_url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
   driver: Wallaby.Chrome,
   capabilities: %{
     headless: true,
     javascriptEnabled: true,
     loadImages: true,
     chromeOptions: %{
       args: ["window-size=1920,1080", "--fullscreen", "--no-sandbox",
        "--disable-gpu", "--disable-extensions", "--disable-login-animations",
        "--no-default-browser-check", "--no-first-run", "--class=bi-int-test",
        "--ignore-certificate-errors"]
     }
   },
   server: Wallaby.Chrome.Chromedriver,
   screenshots: []
 }}
iex(6)> session = visit(session, "https://www.google.com")
%Wallaby.Session{
  id: "33d227e82066ba8f5c47b3673b3e5dad",
  url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
  session_url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
  driver: Wallaby.Chrome,
  capabilities: %{
    headless: true,
    javascriptEnabled: true,
    loadImages: true,
    chromeOptions: %{
      args: ["window-size=1920,1080", "--fullscreen", "--no-sandbox",
       "--disable-gpu", "--disable-extensions", "--disable-login-animations",
       "--no-default-browser-check", "--no-first-run", "--class=bi-int-test",
       "--ignore-certificate-errors"]
    }
  },
  server: Wallaby.Chrome.Chromedriver,
  screenshots: []
}
iex(7)> execute_query(session, Query.text("Google", minimum: 1))
{:ok,
 %Wallaby.Query{
   method: :text,
   selector: "Google",
   html_validation: nil,
   conditions: [
     at: :all,
     selected: :any,
     maximum: nil,
     count: nil,
     text: nil,
     visible: true,
     minimum: 1
   ],
   result: [
     %Wallaby.Element{
       url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad/element/f.545E59863057841406355C036D1A5EAA.d.77C0202D23E61742EFA5BC6C877EDB1C.e.22",
       session_url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
       parent: %Wallaby.Session{
         id: "33d227e82066ba8f5c47b3673b3e5dad",
         url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
         session_url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
         driver: Wallaby.Chrome,
         capabilities: %{
           headless: true,
           javascriptEnabled: true,
           loadImages: true,
           chromeOptions: %{
             args: ["window-size=1920,1080", "--fullscreen", "--no-sandbox",
              "--disable-gpu", "--disable-extensions",
              "--disable-login-animations", "--no-default-browser-check",
              "--no-first-run", "--class=bi-int-test",
              "--ignore-certificate-errors"]
           }
         },
         server: Wallaby.Chrome.Chromedriver,
         screenshots: []
       },
       id: "f.545E59863057841406355C036D1A5EAA.d.77C0202D23E61742EFA5BC6C877EDB1C.e.22",
       driver: Wallaby.Chrome,
       screenshots: []
     }

outerHTML:

<span class="wIbe6e" id="promo_label_id">Sign in to Google</span>,
     %Wallaby.Element{
       url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad/element/f.545E59863057841406355C036D1A5EAA.d.77C0202D23E61742EFA5BC6C877EDB1C.e.23",
       session_url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
       parent: %Wallaby.Session{
         id: "33d227e82066ba8f5c47b3673b3e5dad",
         url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
         session_url: "http://localhost:60679/session/33d227e82066ba8f5c47b3673b3e5dad",
         driver: Wallaby.Chrome,
         capabilities: %{
           headless: true,
           javascriptEnabled: true,
           loadImages: true,
           chromeOptions: %{
             args: ["window-size=1920,1080", "--fullscreen", "--no-sandbox",
              "--disable-gpu", "--disable-extensions",
              "--disable-login-animations", "--no-default-browser-check",
              "--no-first-run", "--class=bi-int-test",
              "--ignore-certificate-errors"]
           }
         },
         server: Wallaby.Chrome.Chromedriver,
         screenshots: []
       },
       id: "f.545E59863057841406355C036D1A5EAA.d.77C0202D23E61742EFA5BC6C877EDB1C.e.23",
       driver: Wallaby.Chrome,
       screenshots: []
     }

outerHTML:

<span class="lUGokd" id="promo_desc_id">Get the most from your Google account</span>
   ]
 }}
iex(8)> Wallaby.end_session(session)
:ok
```

</p>
</details>
<br>
