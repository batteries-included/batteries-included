defmodule CommonUI.Components.Logo do
  @moduledoc false
  use CommonUI, :component

  attr :variant, :string, values: ["full"]
  attr :class, :any, default: nil
  attr :rest, :global

  def logo(%{variant: "full"} = assigns) do
    ~H"""
    <div class={["inline-flex justify-center transition-none animation-none", @class]}>
      <.logo class="size-12 mr-4" />

      <div class="flex flex-col justify-center text-sm leading-none dark:text-gray-light whitespace-nowrap">
        <div class="font-semibold tracking-[0.25rem] mb-1">BATTERIES</div>
        <div class="text-[0.6125rem] tracking-[0.35rem]">INCLUDED</div>
      </div>
    </div>
    """
  end

  def logo(assigns) do
    ~H"""
    <svg
      aria-label="Batteries Included Logo, a cloud with charged ends"
      viewBox="0 0 145 92"
      class={@class}
      {@rest}
    >
      <path
        class="fill-primary"
        d="M36.54,38.3h-4.68c-11.73,0-21.32,9.59-21.32,21.32h0c0,11.73,9.6,21.32,21.32,21.32h27.17c1.4,0,2.76-.14,4.09-.4h-.06c7.83-1.54,14.16-7.4,16.38-14.97-2.83-1.96-4.68-5.23-4.68-8.94,0-6,4.87-10.87,10.87-10.87s10.87,4.87,10.87,10.87c0,4.42-2.64,8.23-6.44,9.93-.05,.21-.09,.41-.14,.61h.06c-3.42,13.85-15.98,24.2-30.84,24.2H31.76C14.29,91.37,0,77.08,0,59.62H0c0-15.85,11.77-29.09,27.01-31.4l-.07-.07C33.69-2.39,69.77-8.99,89.27,12.83,57.24,1.93,38.52,9.66,36.54,38.3h0Zm47.66,12.24v4.68h-4.68v2.84h4.68v4.68h2.84v-4.68h4.68v-2.84h-4.68v-4.68h-2.84Z"
      />
      <path
        class="fill-gray-dark dark:fill-white"
        d="M118.42,35.8c14.48,.15,26.28,12.04,26.28,26.55h0c0,14.61-11.95,26.56-26.56,26.56-10.12,0-17.43-2.12-25.23-9.31h24.02c9.49,0,17.25-7.76,17.25-17.25h0c0-9.49-7.76-17.25-17.25-17.25h-5.27c-3.86-9.35-13.07-15.93-23.81-15.93-11.57,0-21.37,7.64-24.61,18.14,3.16,1.9,5.27,5.36,5.27,9.32,0,6-4.87,10.87-10.87,10.87s-10.87-4.87-10.87-10.87c0-4.22,2.4-7.87,5.91-9.67,3.63-16.08,18-28.09,35.17-28.09,12.88,0,24.19,6.76,30.56,16.92h0Zm-54.68,19.42h-12.19v2.84h12.19v-2.84Z"
      />
    </svg>
    """
  end
end
