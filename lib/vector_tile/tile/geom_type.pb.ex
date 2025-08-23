defmodule VectorTile.Tile.GeomType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  field :UNKNOWN, 0
  field :POINT, 1
  field :LINESTRING, 2
  field :POLYGON, 3
end
