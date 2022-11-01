defmodule ControlServerWeb.FullPageImageLayout do
  use ControlServerWeb, :html

  def full_page_layout(assigns) do
    ~H"""
    <div class="min-h-full flex">
      <div class="flex-1 flex flex-col justify-center py-12 px-4 sm:px-6 lg:flex-none lg:px-20 xl:px-24">
        <div class="mx-auto w-full max-w-sm lg:w-96"><%= render_slot(@inner_block) %></div>
      </div>
      <div class="hidden lg:block relative w-0 flex-1">
        <img
          class="absolute inset-0 h-full w-full object-cover object-top"
          src={image_src(@image_type)}
          alt=""
        />
      </div>
    </div>
    """
  end

  def image_src(:rocket),
    do: ~p"/images/nasa-JkaKy_77wF8-unsplash.jpg"

  def image_src(:hand),
    do: ~p"/images/junior-ferreira-7esRPTt38nI-unsplash.jpg"
end
