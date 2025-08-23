defmodule VectorTile.Tile.Feature do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  field :id, 1, optional: true, type: :uint64, default: 0
  field :tags, 2, repeated: true, type: :uint32, packed: true, deprecated: false
  field :type, 3, optional: true, type: VectorTile.Tile.GeomType, default: :UNKNOWN, enum: true
  field :geometry, 4, repeated: true, type: :uint32, packed: true, deprecated: false
end
