{:ok, _} = Application.ensure_all_started(:wallaby)

Application.put_env(:wallaby, :base_url, ControlServerWeb.Endpoint.url())
ExUnit.start(timeout: 240_000)
