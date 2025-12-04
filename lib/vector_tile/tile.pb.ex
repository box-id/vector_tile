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

  @doc """
  Creates a new `VectorTile.Tile` struct.

  The properties provided in `opts` are set on the struct. While they are not used for encoding the tile, they can be
  useful for coordinate calculations with the `VectorTile.Coordinates` module.

  ## Options

    * `:bbox` - The bounding box of the tile as `[west, south, east, north]`. Optional.
    * `:extent` - The extent of the tile. Optional, defaults to `4096`.

  """
  def new(opts \\ []) do
    struct(__MODULE__, opts)
    |> Map.put(:extent, Keyword.get(opts, :extent, 4096))
    |> Map.put(:bbox, Keyword.get(opts, :bbox, nil))
  end

  # Implement Access behaviour to allow accessing fields like a map.
  @behaviour Access

  @impl Access
  defdelegate fetch(v, key), to: Map

  @impl Access
  defdelegate get_and_update(v, key, func), to: Map

  @impl Access
  defdelegate pop(v, key), to: Map
end
