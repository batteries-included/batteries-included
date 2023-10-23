defmodule Router do
  use Phoenix.Router
end

defmodule Endpoint do
  use Phoenix.Endpoint, otp_app: :common_ui_test

  plug(Router)
end

Application.put_env(:common_ui_test, Endpoint,
  secret_key_base: "lD7uBMl5ZI9BpBTiHr94WvsNW2KtxjkKSDSxv7uq7pNuZi6hk4V2WGjjf7pbd97a",
  live_view: [
    signing_salt: "XhHpDYMxaS/QTwIemO8HZXOxK+zIFsAXQsS1jBoObIw9DROY2GwxTvF0do7Ot4pR"
  ]
)

ExUnit.configure(formatters: [JUnitFormatter, ExUnit.CLIFormatter])
ExUnit.start()
