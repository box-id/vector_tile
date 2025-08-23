defmodule VectorTile.Tile.Layer do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  field :version, 15, required: true, type: :uint32, default: 1
  field :name, 1, required: true, type: :string
  field :features, 2, repeated: true, type: VectorTile.Tile.Feature
  field :keys, 3, repeated: true, type: :string
  field :values, 4, repeated: true, type: VectorTile.Tile.Value
  field :extent, 5, optional: true, type: :uint32, default: 4096

  extensions [{16, Protobuf.Extension.max()}]
end
