defmodule CommonCore.MapSettings do
  @moduledoc """
  This is module provides the `setting` macros. These
  macros make it easier to use a hashmap from
  `ControlServer.Battery.SystemBattery#config`


  You can use it something like this:

  ```
  defmodule CommonCore.ExampleSettings do
    import CommonCore.MapSettings

    setting(:namespace, :namespace, "battery-core")

    def computation_func, do: "computed"
    setting(:test_image, :image) do
      computation_func()
    end
  end
  ```

  After the macros there are the following ways to get the settings with
  overrides set in the map using string or atom keys.

  ## Examples

    iex> CommonCore.ExampleSettings.test_image(%{})
    "computed"

    iex> CommonCore.ExampleSettings.test_image(%{image: "provided"})
    "provided"

    iex> CommonCore.ExampleSettings.namespace(%{})
    "battery-core"
  """

  defmacro setting(name, key, do: default_fn) when is_binary(key) do
    quote do
      def unquote(name)(config) do
        Map.get_lazy(config, unquote(key), fn -> unquote(default_fn) end)
      end
    end
  end

  defmacro setting(name, key, default) when is_binary(key) do
    quote do
      def unquote(name)(config) do
        Map.get(config, unquote(key), unquote(default))
      end
    end
  end

  defmacro setting(name, key, do: default_fn) when is_atom(key) do
    string_key = Atom.to_string(key)

    quote do
      def unquote(name)(config) do
        Map.get(
          config,
          unquote(key),
          Map.get_lazy(config, unquote(string_key), fn -> unquote(default_fn) end)
        )
      end
    end
  end

  defmacro setting(name, key, default) when is_atom(key) do
    string_key = Atom.to_string(key)

    quote do
      def unquote(name)(config) do
        Map.get(
          config,
          unquote(key),
          Map.get(config, unquote(string_key), unquote(default))
        )
      end
    end
  end
end
