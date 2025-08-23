defmodule VectorTile.Tile do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  field :layers, 3, repeated: true, type: VectorTile.Tile.Layer

  extensions [{16, 8192}]
end
