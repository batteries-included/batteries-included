defmodule CommonUI.Icons.Batteries do
  use CommonUI.Component

  attr :class, :any, default: "h-9 w-auto"
  attr :top_cloud_class, :any, default: "fill-gray-500"
  attr :bottom_cloud_class, :any, default: "fill-pink-500"

  def batteries_logo(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 145 92" class={@class}>
      <path
        class={@top_cloud_class}
        d="M36.54,38.3h-4.68c-11.73,0-21.32,9.59-21.32,21.32h0c0,11.73,9.6,21.32,21.32,21.32h27.17c1.4,0,2.76-.14,4.09-.4h-.06c7.83-1.54,14.16-7.4,16.38-14.97-2.83-1.96-4.68-5.23-4.68-8.94,0-6,4.87-10.87,10.87-10.87s10.87,4.87,10.87,10.87c0,4.42-2.64,8.23-6.44,9.93-.05,.21-.09,.41-.14,.61h.06c-3.42,13.85-15.98,24.2-30.84,24.2H31.76C14.29,91.37,0,77.08,0,59.62H0c0-15.85,11.77-29.09,27.01-31.4l-.07-.07C33.69-2.39,69.77-8.99,89.27,12.83,57.24,1.93,38.52,9.66,36.54,38.3h0Zm47.66,12.24v4.68h-4.68v2.84h4.68v4.68h2.84v-4.68h4.68v-2.84h-4.68v-4.68h-2.84Z"
      /><path
        class={@bottom_cloud_class}
        d="M118.42,35.8c14.48,.15,26.28,12.04,26.28,26.55h0c0,14.61-11.95,26.56-26.56,26.56-10.12,0-17.43-2.12-25.23-9.31h24.02c9.49,0,17.25-7.76,17.25-17.25h0c0-9.49-7.76-17.25-17.25-17.25h-5.27c-3.86-9.35-13.07-15.93-23.81-15.93-11.57,0-21.37,7.64-24.61,18.14,3.16,1.9,5.27,5.36,5.27,9.32,0,6-4.87,10.87-10.87,10.87s-10.87-4.87-10.87-10.87c0-4.22,2.4-7.87,5.91-9.67,3.63-16.08,18-28.09,35.17-28.09,12.88,0,24.19,6.76,30.56,16.92h0Zm-54.68,19.42h-12.19v2.84h12.19v-2.84Z"
      />
    </svg>
    """
  end

  def batteries_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="16.41 0.60 41.11 72.73"
      class={@class}
      fill="currentColor"
    >
      <path d="M51.437 72H22.563a4.745 4.745 0 0 1-4.739-4.739V12.91a4.745 4.745 0 0 1 4.739-4.74h28.874a4.745 4.745 0 0 1 4.739 4.739v54.352A4.745 4.745 0 0 1 51.437 72zM22.563 10.17a2.743 2.743 0 0 0-2.739 2.739v54.352A2.743 2.743 0 0 0 22.563 70h28.874a2.743 2.743 0 0 0 2.739-2.739V12.91a2.743 2.743 0 0 0-2.739-2.739z" />
      <path d="M45.217 10.17H28.783a1 1 0 0 1-1-1v-4.3A2.873 2.873 0 0 1 30.652 2h12.7a2.873 2.873 0 0 1 2.87 2.87v4.3a1 1 0 0 1-1.005 1zm-15.435-2h14.435v-3.3a.871.871 0 0 0-.87-.87h-12.7a.871.871 0 0 0-.87.87zm1.327 48.845a1 1 0 0 1-.918-1.395l5.173-12.05h-7.987a1 1 0 0 1-.759-1.651L42.419 23.5a1 1 0 0 1 1.681 1.053l-5.577 12.859h8.1a1 1 0 0 1 .75 1.661l-15.514 17.6a1 1 0 0 1-.75.342zM29.553 41.57h7.329a1 1 0 0 1 .919 1.395l-3.3 7.693 9.911-11.246H37a1 1 0 0 1-.917-1.4l3.549-8.19z" />
    </svg>
    """
  end
end
