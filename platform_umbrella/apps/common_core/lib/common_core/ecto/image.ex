defmodule CommonCore.Ecto.Image do
  @moduledoc false
  use Ecto.Type

  alias CommonCore.Image

  def type, do: :map

  def cast(%Image{} = image), do: {:ok, image}
  def cast(%{} = map), do: Image.new(map)
  def cast(_), do: :error

  # loading from db
  def load(data) when is_map(data), do: Image.new(data)

  # dump to db
  def dump(%Image{} = image), do: {:ok, Map.from_struct(image)}
  def dump(_), do: :error
end
