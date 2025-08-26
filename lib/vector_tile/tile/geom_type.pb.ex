defmodule VectorTile.Tile.GeomType do
  @moduledoc """
  Used to mark the geometry type of a [`Feature`](`VectorTile.Tile.Feature`) as either `:UNKNOWN`, `:POINT`,
  `:LINESTRING`, or `:POLYGON`.
  """

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  field :UNKNOWN, 0
  field :POINT, 1
  field :LINESTRING, 2
  field :POLYGON, 3
end
