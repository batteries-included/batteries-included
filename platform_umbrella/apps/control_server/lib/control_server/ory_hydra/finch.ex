defmodule ControlServer.OryHydraFinch do
  def child_spec do
    {Finch,
     name: __MODULE__,
     pools: %{
       :default => [size: 10]
     }}
  end
end
