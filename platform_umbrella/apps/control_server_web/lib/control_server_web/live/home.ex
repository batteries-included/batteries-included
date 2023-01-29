defmodule ControlServerWeb.Live.Home do
  use ControlServerWeb, {:live_view, layout: :fresh}

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_page_group(:home) |> assign_page_title("Home")}
  end

  def assign_page_group(socket, page_group) do
    assign(socket, page_group: page_group)
  end

  def assign_page_title(socket, page_title) do
    assign(socket, page_title: page_title)
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    Intentionally Empty
    <div class="prose">
      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla tincidunt libero eu erat blandit, eu elementum quam sagittis. Sed sollicitudin turpis in ultricies elementum. Praesent at ipsum et sapien mattis mollis. Vivamus viverra dolor sit amet augue pharetra porttitor. Phasellus eu ante quis tellus rutrum ornare id vitae ante. Aliquam mollis leo faucibus vehicula dignissim. Nulla volutpat ligula ac massa rutrum maximus. Interdum et malesuada fames ac ante ipsum primis in faucibus.
      </p>
      <p>
        Sed gravida vel lectus quis bibendum. Nullam vulputate ex a commodo convallis. Nam luctus sit amet eros at mollis. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Etiam porta tellus ut urna lacinia congue. Etiam feugiat, diam eu tempus tristique, nisl risus porttitor augue, in ullamcorper quam justo eget massa. Integer pharetra mauris ut justo efficitur, at suscipit lorem vestibulum. Donec eget blandit metus, tincidunt iaculis lorem. Cras in justo ut magna scelerisque pharetra. Suspendisse pulvinar mauris ornare tortor feugiat dictum. Donec id pellentesque augue. In mauris eros, maximus vitae aliquet vitae, laoreet vel elit. In mi arcu, accumsan eu arcu sed, sodales imperdiet tellus. Vivamus sit amet arcu at mauris facilisis accumsan. In ac nibh euismod, gravida quam eget, ullamcorper ligula.
      </p>
      <p>
        Quisque bibendum justo posuere condimentum mollis. Praesent maximus est sit amet ligula laoreet, ac tincidunt odio aliquet. Sed quis sapien vel nisi sollicitudin aliquet ut rutrum quam. Nulla sagittis metus blandit ante pellentesque, ut hendrerit justo dictum. Pellentesque aliquet nisi sit amet est tempor, quis fringilla ipsum mattis. Vestibulum laoreet risus quis dolor ultrices dignissim. Aenean dapibus egestas finibus. Phasellus dui eros, consequat non tincidunt eu, sodales eu mi. Sed sed vehicula lorem, at dictum diam. Duis vitae vestibulum ex. Maecenas dictum purus a mauris mattis eleifend. Sed vehicula est et justo volutpat, a tincidunt dolor vestibulum. Quisque eleifend lacus non risus sagittis, sed tempus eros molestie. Aliquam erat volutpat.
      </p>
      <p>
        Pellentesque mollis est quis arcu scelerisque lobortis eget quis nulla. Praesent at justo dignissim, rutrum lorem id, lacinia sem. Proin consectetur volutpat tortor, at molestie sapien porta quis. Duis lacinia eget est id vehicula. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas lobortis magna at egestas blandit. Nam auctor risus id viverra commodo.
      </p>
      <p>
        Morbi sit amet eros feugiat, ultrices purus vel, rhoncus tellus. Donec id hendrerit turpis. Donec eu malesuada felis, sed convallis purus. Vivamus vel fermentum orci. Maecenas quis dignissim lorem. Ut tortor nibh, bibendum sed leo a, rhoncus cursus urna. In eu lacinia quam. Aenean accumsan leo ligula, ac pretium nisl ultricies non.
      </p>
      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla tincidunt libero eu erat blandit, eu elementum quam sagittis. Sed sollicitudin turpis in ultricies elementum. Praesent at ipsum et sapien mattis mollis. Vivamus viverra dolor sit amet augue pharetra porttitor. Phasellus eu ante quis tellus rutrum ornare id vitae ante. Aliquam mollis leo faucibus vehicula dignissim. Nulla volutpat ligula ac massa rutrum maximus. Interdum et malesuada fames ac ante ipsum primis in faucibus.
      </p>
      <p>
        Sed gravida vel lectus quis bibendum. Nullam vulputate ex a commodo convallis. Nam luctus sit amet eros at mollis. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Etiam porta tellus ut urna lacinia congue. Etiam feugiat, diam eu tempus tristique, nisl risus porttitor augue, in ullamcorper quam justo eget massa. Integer pharetra mauris ut justo efficitur, at suscipit lorem vestibulum. Donec eget blandit metus, tincidunt iaculis lorem. Cras in justo ut magna scelerisque pharetra. Suspendisse pulvinar mauris ornare tortor feugiat dictum. Donec id pellentesque augue. In mauris eros, maximus vitae aliquet vitae, laoreet vel elit. In mi arcu, accumsan eu arcu sed, sodales imperdiet tellus. Vivamus sit amet arcu at mauris facilisis accumsan. In ac nibh euismod, gravida quam eget, ullamcorper ligula.
      </p>
      <p>
        Quisque bibendum justo posuere condimentum mollis. Praesent maximus est sit amet ligula laoreet, ac tincidunt odio aliquet. Sed quis sapien vel nisi sollicitudin aliquet ut rutrum quam. Nulla sagittis metus blandit ante pellentesque, ut hendrerit justo dictum. Pellentesque aliquet nisi sit amet est tempor, quis fringilla ipsum mattis. Vestibulum laoreet risus quis dolor ultrices dignissim. Aenean dapibus egestas finibus. Phasellus dui eros, consequat non tincidunt eu, sodales eu mi. Sed sed vehicula lorem, at dictum diam. Duis vitae vestibulum ex. Maecenas dictum purus a mauris mattis eleifend. Sed vehicula est et justo volutpat, a tincidunt dolor vestibulum. Quisque eleifend lacus non risus sagittis, sed tempus eros molestie. Aliquam erat volutpat.
      </p>
      <p>
        Pellentesque mollis est quis arcu scelerisque lobortis eget quis nulla. Praesent at justo dignissim, rutrum lorem id, lacinia sem. Proin consectetur volutpat tortor, at molestie sapien porta quis. Duis lacinia eget est id vehicula. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas lobortis magna at egestas blandit. Nam auctor risus id viverra commodo.
      </p>
      <p>
        Morbi sit amet eros feugiat, ultrices purus vel, rhoncus tellus. Donec id hendrerit turpis. Donec eu malesuada felis, sed convallis purus. Vivamus vel fermentum orci. Maecenas quis dignissim lorem. Ut tortor nibh, bibendum sed leo a, rhoncus cursus urna. In eu lacinia quam. Aenean accumsan leo ligula, ac pretium nisl ultricies non.
      </p>
    </div>
    """
  end
end
