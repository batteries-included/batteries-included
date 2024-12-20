defmodule ControlServerWeb.ObjectDisplay do
  @moduledoc false
  use ControlServerWeb, :html

  attr :base_url, :string, default: "/"
  attr :path, :any, default: []
  attr :object, :any, default: %{}

  def object_display(assigns) do
    ~H"""
    <.flex class="overflow-x-auto focus:outline-none full-screen-minus mx-2">
      <.column
        :for={idx <- 0..length(@path)}
        path={Enum.slice(@path, 0, idx)}
        object={sub_obj(@object, Enum.slice(@path, 0, idx))}
        base_url={@base_url}
      />
    </.flex>
    """
  end

  attr :selected, :string, default: nil

  defp column_title(%{selected: nil} = assigns) do
    ~H"""
    <.h3 class="my-4">Root</.h3>
    """
  end

  defp column_title(assigns) do
    ~H"""
    <.h3 class="my-4">{titleize(@selected)}</.h3>
    """
  end

  defp titleize(name) do
    name
    |> String.replace(["-", "_", "/", "."], " ")
    |> String.replace(~r/([A-Z]+)/, " \\1")
    |> String.downcase()
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
    |> String.trim()
  end

  attr :base_url, :string, default: "/"
  attr :path, :any, default: []
  attr :object, :any, default: %{}
  attr :class, :string, default: "flex-none border-r-[1px] border-gray-lighter/90 w-96 overflow-x-clip"

  defp column(%{object: object} = assigns) when is_map(object) or is_list(object) do
    ~H"""
    <div class={@class}>
      <.flex column class="h-full overflow-y-auto">
        <.column_title selected={selected(@path)} />
        <.column_data object={@object} path={@path} base_url={@base_url} />
      </.flex>
    </div>
    """
  end

  defp column(assigns) do
    ~H"""
    <div class={@class}>
      <.flex column class="h-full overflow-y-auto">
        <.column_title selected={selected(@path)} />
        <.truncate_tooltip value={to_string(@object)} class="text-md" />
      </.flex>
    </div>
    """
  end

  attr :base_url, :string, default: "/"
  attr :path, :any, default: []
  attr :object, :any, default: %{}
  attr :class, :string, default: "group hover:bg-pink-500/10 rounded-md"
  attr :flex_class, :string, default: "justify-between align-center p-1"
  attr :icon_class, :string, default: "text-gray w-6 my-auto group-hover:text-primary-dark"

  defp column_data(%{object: object} = assigns) when is_map(object) do
    ~H"""
    <.a
      :for={{key, value} <- @object}
      patch={object_path_url(@base_url, @path ++ [key])}
      class={@class}
      variant="unstyled"
    >
      <.flex class={@flex_class}>
        <.value_icon value_type={value_type(value)} class={@icon_class} />
        <span>{key}</span>
        <.icon name={:chevron_double_right} class={["w-6 h-6 text-gray"]} />
      </.flex>
    </.a>
    """
  end

  defp column_data(%{object: object} = assigns) when is_list(object) do
    ~H"""
    <.a
      :for={{value, idx} <- Enum.with_index(@object)}
      patch={object_path_url(@base_url, @path ++ [Integer.to_string(idx)])}
      class={@class}
      variant="unstyled"
    >
      <.flex class={@flex_class}>
        <.value_icon value_type={value_type(value)} class={@icon_class} />
        <span>Index {idx}</span>
        <.icon name={:chevron_double_right} class={["w-6 h-6 text-gray"]} />
      </.flex>
    </.a>
    """
  end

  attr :value_type, :atom, required: true
  attr :class, :any, default: nil

  defp value_icon(%{value_type: :map} = assigns) do
    ~H"""
    <.icon name={:cube} mini class={[@class]} />
    """
  end

  defp value_icon(%{value_type: :string} = assigns) do
    ~H"""
    <svg
      version="1.1"
      viewBox="0 0 1000 1000"
      enable-background="new 0 0 1000 1000"
      fill="currentColor"
      class={[@class]}
    >
      <g>
        <path d="M523.9,852.4L534,744.4c175-38.6,262.6-110.6,262.6-216.1c0-30.2-28.1-62.8-84.2-98c-55.3-35.2-82.9-78.8-82.9-130.7c0-46.1,14.7-82.9,44-110.6c29.3-27.6,67.8-41.4,115.5-41.4c56.2,0,103.7,19.5,142.6,58.4c39,38.9,58.4,89.8,58.4,152.7c0,123.9-39.8,229.4-119.3,316.6C791.1,762.3,675.5,821.4,523.9,852.4 M10,852.4l10-108.1c175.1-39.5,262.6-111.4,262.6-216.1c0-30.2-28-62.8-84.1-98c-55.3-35.2-82.9-78.8-82.9-130.7c0-46.1,14.4-82.9,43.3-110.6c28.9-27.6,67.6-41.4,116.2-41.4c56.9,0,104.5,19.5,142.6,58.4c38.1,38.9,57.2,89.8,57.2,152.7c0,125.6-39.8,231.8-119.4,318.5C275.9,763.9,160.8,822.3,10,852.4" />
      </g>
    </svg>
    """
  end

  defp value_icon(%{value_type: :number} = assigns) do
    ~H"""
    <svg
      version="1.1"
      viewBox="0 0 1000 1000"
      enable-background="new 0 0 1000 1000"
      fill="currentColor"
      class={[@class]}
    >
      <g>
        <g transform="matrix(1 0 0 -1 0 960)">
          <path d="M193.7-30c-5.4,0-9.9,1.9-13.5,5.7c-3.5,3.8-4.8,8.7-3.7,14.7L214.2,215H71.3c-5.4,0-9.9,1.9-13.5,5.7c-3.5,3.8-4.8,8.7-3.7,14.7l20.4,122.5c1.1,6,3.9,10.9,8.6,14.7s9.7,5.7,15.1,5.7h142.9l27.8,163.3H126c-6,0-10.6,1.9-13.9,5.7c-3.3,3.8-4.4,8.7-3.3,14.7l20.4,122.5c0.5,3.8,2,7.2,4.5,10.2c2.5,3,5.3,5.4,8.6,7.4c3.3,1.9,6.8,2.9,10.6,2.9h142.9l37.6,224.6c1.1,6,3.9,10.9,8.6,14.7c4.6,3.8,9.7,5.7,15.1,5.7h122.5c5.4,0,9.9-1.9,13.5-5.7c3.5-3.8,4.8-8.7,3.7-14.7L459.2,705h163.3l37.6,224.6c1.1,6,3.9,10.9,8.6,14.7c4.6,3.8,9.7,5.7,15.1,5.7h122.5c5.4,0,9.9-1.9,13.5-5.7c3.5-3.8,4.8-8.7,3.7-14.7L785.8,705h142.9c5.4,0,9.9-1.9,13.5-5.7c3.5-3.8,4.8-8.7,3.7-14.7l-20.4-122.5c-0.5-3.8-2-7.2-4.5-10.2c-2.4-3-5.4-5.4-9-7.4c-3.5-1.9-6.9-2.9-10.2-2.9H758.9l-27.8-163.3H874c3.8,0,7.2-1,10.2-2.9c3-1.9,5-4.4,6.1-7.3c1.1-3,1.4-6.4,0.8-10.2l-20.4-122.5c-1.1-6-3.9-10.9-8.6-14.7c-4.6-3.8-9.7-5.7-15.1-5.7H704.2L666.6-9.6c-0.5-3.8-2-7.2-4.5-10.2c-2.5-3-5.3-5.4-8.6-7.4c-3.3-1.9-6.8-2.9-10.6-2.9H520.4c-5.4,0-9.9,1.9-13.5,5.7c-3.5,3.8-4.8,8.7-3.7,14.7L540.8,215H377.5L339.9-9.6c-1.1-6-3.9-10.9-8.6-14.7c-4.6-3.8-9.7-5.7-15.1-5.7H193.7z M404.4,378.3h163.3l27.8,163.3H432.2L404.4,378.3z" />
        </g>
      </g>
    </svg>
    """
  end

  defp value_icon(%{value_type: :list} = assigns) do
    ~H"""
    <.icon name={:list_bullet} mini class={[@class]} />
    """
  end

  defp value_icon(%{value_type: :boolean} = assigns) do
    ~H"""
    <.icon name={:check_circle} mini class={[@class]} />
    """
  end

  defp value_icon(assigns), do: ~H||

  defp value_type(value) when is_map(value), do: :map
  defp value_type(value) when is_binary(value), do: :string
  defp value_type(value) when is_number(value), do: :number
  defp value_type(value) when is_list(value), do: :list
  defp value_type(value) when is_boolean(value), do: :boolean
  defp value_type(_value), do: :unknown

  defp object_path_url(base_path, object_path_list) do
    op = Plug.Conn.Query.encode(path: object_path_list)
    "#{base_path}?#{op}"
  end

  defp selected(path) do
    List.last(path, nil)
  end

  defp sub_obj(resource, path) do
    Enum.reduce(path, resource, fn
      path_part, curr when is_list(curr) ->
        Enum.at(curr, String.to_integer(path_part))

      path_part, curr when is_map(curr) ->
        Map.get(curr, path_part)
    end)
  end
end
