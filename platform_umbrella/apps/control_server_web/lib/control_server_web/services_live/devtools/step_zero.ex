defmodule ControlServerWeb.ServicesLive.DevtoolsStepZero do
  use Surface.Component

  alias CommonUI.Button
  prop(next_event, :event, required: false)

  def render(assigns) do
    ~F"""
    <div class="px-4 py-5 sm:px-6">
      <!-- We use less vertical padding on card headers on desktop than on body sections -->
      <h1 class="mt-2 text-2xl font-bold leading-7 text-astral-500 sm:text-xl sm:truncate">Install devtools</h1>
      <div class="m-4 text-lg row">
        Our source code is located in
        <select class="inline py-2 pl-3 pr-10 mt-1 text-base border-gray-300 rounded-md focus:outline-none focus:ring-pink-500 focus:border-pink-500 sm:text-sm">
          <option>Github</option>
          <option selected>Gitlab</option>
          <option>Other</option>
        </select>
        Batteries included will start start testing runners. So that your repositories
        are well tested before being deployed. We'll ask for security permissions
        and other details next. Please have those ready.
      </div>

      <div class="flex flex-row-reverse">
        <Button class={["w-32"]} click="progress:change" phx_payload={1}>
          Next
        </Button>
      </div>
    </div>
    """
  end
end
