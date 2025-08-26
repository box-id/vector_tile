defmodule VectorTile.Tile.Feature do
  @moduledoc """
  Represents a [feature](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#42-features) that can be part of a
  [`Layer`](`VectorTile.Tile.Layer`) and contains a geometry as well as a set of attributes.

  Due to the way attributes are reused across a layer's features, don't manage `tags` directly and use
  [`Layer.add_feature/3`](`VectorTile.Tile.Layer.add_feature/3`) instead.

  See [Geometry Encoding](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#43-geometry-encoding) when defining
  the geometry of a feature, as this library currently provides no helpers to do this except for `zigzag/1`.

  To produce a feature's geometry with known geo coordinates in WGS 84, the steps are generally as follows:

  1. Project the feature's coordinates & the tile's bounds to [Web
     Mercator](https://en.wikipedia.org/wiki/Web_Mercator_projection), e.g. using
     [SphericalMercator](https://hex.pm/packages/spherical_mercator).
  2. Perform a linear interpolation relative to the tile's boundaries into the 4096x4096 "pixel" grid.
  3. Choose the correct
     [*CommandInteger*(s)](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#431-command-integers) and
     zigzag-encode the x and y coordinates
     ([*ParameterInteger*](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#432-parameter-integers)).

  ## Example

      iex> import VectorTile.Tile.Feature
      iex> feature = %VectorTile.Tile.Feature{
      ...>   type: :POINT,
      ...>   geometry: [
      ...>     9, # MoveTo command with 1 following pair of coordinates
      ...>     zigzag(250),
      ...>     zigzag(500)
      ...>   ]
      ...> }
      %VectorTile.Tile.Feature{}
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  field :id, 1, optional: true, type: :uint64, default: 0
  field :tags, 2, repeated: true, type: :uint32, packed: true, deprecated: false
  field :type, 3, optional: true, type: VectorTile.Tile.GeomType, default: :UNKNOWN, enum: true
  field :geometry, 4, repeated: true, type: :uint32, packed: true, deprecated: false

  @neg_max -1 * 2 ** 31
  @pos_max 2 ** 31

  @doc """
  Zigzag encodes an
  [*ParameterInteger*](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#432-parameter-integers).

  Supports values greater than -2^31 and less than 2^31.
  """
  @spec zigzag(integer()) :: integer()
  def zigzag(value) when is_integer(value) and @neg_max < value and value < @pos_max do
    import Bitwise

    Bitwise.bxor(value <<< 1, value >>> 31)
  end
end
