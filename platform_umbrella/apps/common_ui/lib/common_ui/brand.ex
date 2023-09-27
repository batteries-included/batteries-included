defmodule CommonUI.Brand do
  @moduledoc false
  use CommonUI.Component

  import CommonUI.Icons.Batteries

  attr :class, :string, default: nil

  def logo(assigns) do
    ~H"""
    <div class={["inline-flex h-10 justify-center transition-none animation-none", @class]}>
      <.batteries_logo class="w-10 h-auto mr-4" />
      <div class="flex flex-col justify-between h-8 my-auto text-sm leading-none align-middle dark:text-gray-300 whitespace-nowrap">
        <span class="font-semibold tracking-[0.25rem] uppercase">
          Batteries
        </span>
        <span class="tracking-[0.35rem] text-[0.6125rem] uppercase">
          Included
        </span>
      </div>
    </div>
    """
  end
end
