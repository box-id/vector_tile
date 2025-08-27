defmodule VectorTile.LayerTransformer do
  @moduledoc false

  @behaviour Protobuf.TransformModule

  alias VectorTile.{
    Layer,
    Value
  }

  # Transformer for Layer structs that turns `__values__` index into `values` list of Value structs.
  @impl Protobuf.TransformModule
  def encode(%{__values__: %{} = value_cache} = layer, Layer) do
    values =
      value_cache
      |> Enum.sort_by(fn {_value, index} -> index end)
      |> Enum.map(fn {value, _index} -> Value.from_plain(value) end)

    %{layer | values: values} |> Map.delete(:__values__)
  end

  def encode(layer, Layer), do: layer

  @impl Protobuf.TransformModule
  def decode(value, Layer), do: value
end
