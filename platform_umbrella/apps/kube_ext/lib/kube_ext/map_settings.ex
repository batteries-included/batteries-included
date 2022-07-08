defmodule KubeExt.MapSettings do
  @moduledoc """
  This is module provices the `setting` and `setting_fn` macros. These
  macros make it easier to use a hashmap from
  `ControlServer.Services.BaseService#config`


  You can use it something like this:

  ```
  defmodule KubeExt.ExampleSettings do
    import KubeExt.MapSettings

    setting(:namespace, :namespace, "battery-core")
    def default_func, do: "computed"

    setting_fn(:test_image, :image, &default_func/0)
  end
  ```

  After the macros there are the following ways to get the settings with
  overrides set in the map using string or atom keys.

  ## Examples

    iex> KubeExt.ExampleSettings.test_image(%{})
    "computed"

    iex> KubeExt.ExampleSettings.test_image(%{image: "provided"})
    "provided"

    iex> KubeExt.ExampleSettings.namespace(%{})
    "battery-core"

    iex> KubeExt.ExampleSettings.namespace()
    "battery-core"
  """

  defmacro setting_fn(name, key, default_fn) when is_binary(key) do
    quote do
      def unquote(name)(config \\ %{}) do
        default_value = apply(unquote(default_fn), [])
        Map.get(config, unquote(key), default_value)
      end
    end
  end

  defmacro setting(name, key, default) when is_binary(key) do
    quote do
      def unquote(name)(config \\ %{}) do
        Map.get(config, unquote(key), unquote(default))
      end
    end
  end

  defmacro setting_fn(name, key, default_fn) when is_atom(key) do
    string_key = Atom.to_string(key)

    quote do
      def unquote(name)(config \\ %{}) do
        default_value = apply(unquote(default_fn), [])

        Map.get(
          config,
          unquote(key),
          Map.get(config, unquote(string_key), default_value)
        )
      end
    end
  end

  defmacro setting(name, key, default) when is_atom(key) do
    string_key = Atom.to_string(key)

    quote do
      def unquote(name)(config \\ %{}) do
        Map.get(
          config,
          unquote(key),
          Map.get(config, unquote(string_key), unquote(default))
        )
      end
    end
  end
end
