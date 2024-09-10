defmodule CommonCore.Env do
  @moduledoc false

  defmacro dev_env? do
    quote do
      Enum.member?([:dev, :test], Mix.env())
    end
  end
end
