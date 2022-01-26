defmodule ControlServerWeb.ServicesLive.DevtoolsInstall do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout
  import ControlServerWeb.ServicesLive.DevtoolsStepZero

  alias CommonUI.Progress

  require Logger

  def handle_event("progress:change" = e_name, %{"payload" => index} = e, socket) do
    {int_val, ""} = Integer.parse(index)
    Logger.debug("Got #{e_name}  payload = #{inspect(e)} for socket = #{inspect(socket)}")

    {:noreply, assign(socket, :step, int_val)}
  end

  def render(assigns) do
    ~H"""
    <.layout>
      <div class="max-w-4xl mx-auto">
        <div class="flex flex-col overflow-hidden bg-white divide-y divide-gray-200 rounded-lg shadow">
          <.step_zero />
          <div class="px-4 py-5 sm:p-6">
            <Progress.progress_holder>
              <Progress.step name="Github/Gitlab" index={0} is_done={@step >= 0} change="progress:change" />
              <Progress.step name="Details" index={1} is_done={@step >= 1} change="progress:change" />
              <Progress.step name="Preview" index={2} is_done={@step >= 2} change="progress:change" />
            </Progress.progress_holder>
          </div>
        </div>
      </div>
    </.layout>
    """
  end
end
