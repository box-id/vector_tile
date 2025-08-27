defmodule VectorTile.Tile do
  @moduledoc """
  Represents a vector tile, which is a collection of [`Layer`](`VectorTile.Layer`)s.

  Use [`protobuf`](https://hexdocs.pm/protobuf)s [`encode/1`](https://hexdocs.pm/protobuf/Protobuf.html#c:encode/1) or
  [`encode_to_iodata/1`](https://hexdocs.pm/protobuf/Protobuf.html#c:encode_to_iodata/1) to encode the tile to a
  Protocol Buffer.

  ### Example

      iex> tile = %VectorTile.Tile{
      ...>   layers: [layer_1, layer_2]
      ...> }
      %VectorTile.Tile{}

      iex> Tile.encode(tile)
      <<...>>
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  field :layers, 3, repeated: true, type: VectorTile.Layer

  extensions [{16, 8192}]
end
