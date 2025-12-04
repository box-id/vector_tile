defmodule VectorTile.Coordinates do
  @moduledoc """
  Functions for working with coordinates in vector tiles, including interpolation into a tile's internal coordinate
  system and zigzag encoding of parameter integers.
  """

  @doc """
  Interpolates a point `[x, y]` to a [tile's internal coordinate
  system](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#43-geometry-encoding) based on bounding box and
  extent.

  You can call this function with a `VectorTile.Tile` that has been initialized with a bounding box and an extent, or
  provide a keyword list with these keys:

  - `:bbox` - list of four numbers representing `[west, south, east, north]`
  - `:extent` - integer representing the tile's extent (default is 4096)

  ## Example

      iex> tile = VectorTile.Tile.new(bbox: [10, 0, 20, 10], extent: 4096)
      iex> interpolate([15, 10], tile)
      [2048, 0]
      # x = 2048, because it's halfway between the east and west edges
      # y = 0, because it's on the north edge of the tile's bounding box

  """
  @spec interpolate(coordinate :: list(number()), tile :: map() | Keyword.t()) :: list(integer())
  def interpolate([x, y] = _coordinate, opts) when is_number(x) and is_number(y) do
    bbox = Access.fetch!(opts, :bbox)
    extent = Access.get(opts, :extent, 4096)

    [
      interpolate_x(bbox, extent, x),
      interpolate_y(bbox, extent, y)
    ]
  end

  defp interpolate_x([tile_w, _tile_s, tile_e, _tile_n], extent, x) do
    if tile_e == tile_w,
      do: 0,
      else: ((x - tile_w) / (tile_e - tile_w) * extent) |> floor()
  end

  defp interpolate_y([_tile_w, tile_s, _tile_e, tile_n], extent, y) do
    if tile_n == tile_s,
      do: 0,
      else: ((tile_n - y) / (tile_n - tile_s) * extent) |> floor()
  end

  @neg_max -1 * 2 ** 31
  @pos_max 2 ** 31

  @doc """
  Zigzag encodes an
  [*ParameterInteger*](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#432-parameter-integers).

  Supports values greater than -2^31 and less than 2^31.

  ## Example

      iex> Coordinates.zigzag(0)
      0

      iex> Coordinates.zigzag(1)
      2

      iex> Coordinates.zigzag(-1)
      1

      iex> Coordinates.zigzag(2)
      4

      iex> Coordinates.zigzag(-2)
      3

      iex> Coordinates.zigzag(2 ** 31 - 1)
      4294967294

      iex> Coordinates.zigzag(-1 * (2 ** 31 - 1))
      4294967293

      iex> Coordinates.zigzag(2 ** 31)
      ** (FunctionClauseError) no function clause matching in VectorTile.Coordinates.zigzag/1

      iex> Coordinates.zigzag(-1 * 2 ** 31)
      ** (FunctionClauseError) no function clause matching in VectorTile.Coordinates.zigzag/1
  """
  @spec zigzag(integer()) :: integer()
  def zigzag(value) when is_integer(value) and @neg_max < value and value < @pos_max do
    import Bitwise

    Bitwise.bxor(value <<< 1, value >>> 31)
  end
end
