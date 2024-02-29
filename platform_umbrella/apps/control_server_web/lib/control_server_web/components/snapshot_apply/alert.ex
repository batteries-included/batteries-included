defmodule ControlServerWeb.SnapshotApplyAlert do
  @moduledoc false

  use ControlServerWeb, :html

  def pause_alert(assigns) do
    ~H"""
    <div class="rounded-md bg-secondary/50 dark:bg-gray/10 text-black dark:text-white text-center text-md p-2 shadow-sm">
      Deploys are currently paused
    </div>
    """
  end
end
