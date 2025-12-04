defmodule VectorTile.Feature do
  @moduledoc """
  Represents a [feature](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#42-features) that can be part of a
  [`Layer`](`VectorTile.Layer`) and contains a geometry as well as a set of attributes.

  Due to the way attributes are reused across a layer's features, don't manage `tags` directly and use
  [`Layer.add_feature/3`](`VectorTile.Layer.add_feature/3`) instead.

  To produce a feature's geometry with geo coordinates in WGS 84, the steps are generally as follows:

  1. Project the feature's coordinates & the tile's bounds to [Web
     Mercator](https://en.wikipedia.org/wiki/Web_Mercator_projection), e.g. using
     [SphericalMercator](https://hex.pm/packages/spherical_mercator).
  2. Perform a linear interpolation relative to the tile's boundaries into the 4096x4096 "pixel" grid. You can use the
     `VectorTile.Coordinates.interpolate/2` function for this.
  3. Choose the correct
     [*CommandInteger*](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#431-command-integers), e.g. through
     `command/2` and zigzag-encode the x and y coordinates
     ([*ParameterInteger*](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#432-parameter-integers)) using
     `VectorTile.Coordinates.zigzag/1`.

  ## Geometry Helpers

  For some geometry types, helper functions are provided to create features from geometry structures. The geometry is
  expected to be provided as a list of coordinate pairs, each as `[x, y]`.

  - `point/2` - creates a `:POINT` feature from a single point `[x, y]`.
  - `multi_point/2` - creates a `:POINT` feature from multiple points `[[x1, y1], [x2, y2], ...]`.
  - `polygon/2` - creates a `:POLYGON` feature from a single polygon `[[x1, y1], [x2, y2], ...]`.
  - `multi_polygon/2` - creates a `:POLYGON` feature from multiple polygons `[[[x11, y11], [x12, y12], ...], [[x21,
    y21], [x22, y22], ...], ...]`.

  All of these functions accept an optional `:project` option, which should be a function that takes a point `[x, y]`
  and returns a projected point `[x', y']`. This can be used to perform coordinate system transformations before
  encoding the geometry, without needing to manually project each point beforehand.

  Note that zigzag encoding and command integers are handled automatically by these helper functions.

  #### Example

      iex> tile = VectorTile.Tile.new(bbox: [10, 0, 20, 10], extent: 4096)
      ...> multi_point(
      ...>   [
      ...>     [15, 5],
      ...>     [16, 6]
      ...>   ],
      ...>   project: &VectorTile.Coordinates.interpolate(&1, tile)
      ...> )
      %Feature{
        type: :POINT,
        geometry: [17, 4096, 4096, 818, 819]
      }

  ## Raw Geometry Example

  Construct a feature in accordance with [Geometry
  Encoding](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#43-geometry-encoding) from raw geometry commands
  and coordinates relative to the tile's coordinate system:

      iex> %Feature{
      ...>   type: :POINT,
      ...>   geometry: [
      ...>     9, # MoveTo command with 1 following pair of coordinates
      ...>     VectorTile.Coordinates.zigzag(250),
      ...>     VectorTile.Coordinates.zigzag(500)
      ...>   ]
      ...> }
      %Feature{
        type: :POINT,
        geometry: [9, 500, 1000]
      }
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  import Bitwise, only: [<<<: 2, |||: 2, &&&: 2]

  field :id, 1, optional: true, type: :uint64, default: 0
  field :tags, 2, repeated: true, type: :uint32, packed: true, deprecated: false
  field :type, 3, optional: true, type: VectorTile.GeomType, default: :UNKNOWN, enum: true
  field :geometry, 4, repeated: true, type: :uint32, packed: true, deprecated: false

  @doc """
  Creates a Feature of type `:POINT` from a single point `[x, y]`.

  `x` and `y` must be integers in the tile's coordinate system (usually 0..4096). Use the `:project` option to provide a
  projection function if your input coordinates are in a different system.

  ## Example

      iex> point([25, 17])
      %Feature{
        type: :POINT,
        geometry: [9, 50, 34]
      }
  """
  def point([x, y] = point, opts \\ []) when is_number(x) and is_number(y),
    do: multi_point([point], opts)

  @doc """
  Creates a Feature of type `:POINT` with multiple geometries from a list of points `[[x1, y1], [x2, y2], ...]`.

  `x` and `y` must be integers in the tile's coordinate system (usually 0..4096). Use the `:project` option to provide a
  projection function if your input coordinates are in a different system.

  ## Example

      iex> multi_point([[5, 7], [3, 2]])
      %Feature{
        type: :POINT,
        geometry: [17, 10, 14, 3, 9]
      }
  """
  def multi_point(points, opts \\ [])

  def multi_point([[x, y] | _] = points, opts) when is_number(x) and is_number(y) do
    {geometry, _cursor} =
      Enum.flat_map_reduce(points, {0, 0}, fn point, {last_x, last_y} ->
        [x, y] = project(point, opts)

        coordinates = [
          zigzag(x - last_x),
          zigzag(y - last_y)
        ]

        {coordinates, {x, y}}
      end)

    struct(__MODULE__, %{
      type: :POINT,
      geometry: [
        command(:move_to, Enum.count(points)) | geometry
      ]
    })
  end

  @doc """
  Creates a Feature of type `:POLYGON` from a single polygon `[[x1, y1], [x2, y2], ...]`.

  `x` and `y` must be integers in the tile's coordinate system (usually 0..4096). Use the `:project` option to provide a
  projection function if your input coordinates are in a different system.

  The polygon ring must be clockwise (to be an exterior ring) as per [Polygon Geometry
  Type](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#4344-polygon-geometry-type). This function does not
  validate the winding order of the ring.

  The ring should **not** repeat the starting point at the end.

  ## Example

      iex> polygon([[3, 6], [8, 12], [20, 34]])
      %Feature{
        type: :POLYGON,
        geometry: [9, 6, 12, 18, 10, 12, 24, 44, 15]
      }
  """
  def polygon([[x, y] | _] = polygon, opts \\ []) when is_number(x) and is_number(y),
    do: multi_polygon([polygon], opts)

  @doc """
  Creates a Feature of type `:POLYGON` from multiple polygons `[[[x11, y11], [x12, y12], ...], [[x21, y21], [x22, y22],
  ...], ...]`.

  `x` and `y` must be integers in the tile's coordinate system (usually 0..4096). Use the `:project` option to provide a
  projection function if your input coordinates are in a different system.

  The first polygon ring must be clockwise (to be an exterior ring) as per [Polygon Geometry
  Type](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#4344-polygon-geometry-type). Following rings can also
  be counter-clockwise (to be interior rings). This function does not validate the winding order of the rings.

  All rings should **not** repeat the starting point at the end.

  ## Example

      iex> multi_polygon([
      ...>   [[11, 11], [20, 11], [20, 20], [11, 20]],
      ...>   [[13, 13], [13, 17], [17, 17], [17, 13]]
      ...> ])
      %Feature{
        type: :POLYGON,
        geometry: [9, 22, 22, 26, 18, 0, 0, 18, 17, 0, 15, 9, 4, 13, 26, 0, 8, 8, 0, 0, 7, 15]
      }
  """
  def multi_polygon(polygons, opts \\ [])

  def multi_polygon([[[x, y] | _] | _] = polygons, opts) when is_number(x) and is_number(y) do
    {geometry, _cursor} =
      Enum.flat_map_reduce(polygons, {0, 0}, fn ring, cursor ->
        draw_ring(ring, cursor, opts)
      end)

    struct(__MODULE__, %{
      type: :POLYGON,
      geometry: geometry
    })
  end

  defp draw_ring([point | other_points], {last_x, last_y}, opts) do
    [x, y] = project(point, opts)

    move_to = [
      command(:move_to),
      zigzag(x - last_x),
      zigzag(y - last_y),
      command(:line_to, Enum.count(other_points))
    ]

    {line_positions, cursor} =
      Enum.flat_map_reduce(other_points, {x, y}, fn point, {last_x, last_y} ->
        [x, y] = project(point, opts)

        coordinates = [
          zigzag(x - last_x),
          zigzag(y - last_y)
        ]

        {coordinates, {x, y}}
      end)

    close_path = [command(:close_path)]

    {move_to ++ line_positions ++ close_path, cursor}
  end

  # Command Integers: https://github.com/mapbox/vector-tile-spec/tree/master/2.1#431-command-integers
  @cmd_move_to 1
  @cmd_line_to 2
  @cmd_close_path 7

  @doc """
  Builds a [*CommandInteger*](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#431-command-integers) for the
  given command and parameter count.

  - The available commands are `:move_to`, `:line_to`, and `:close_path`.
  - `count` must be a non-negative integer and defaults to `1`. The `:close_path` command only supports a count of `1`.

  ## Example

      iex> command(:move_to)
      9

      iex> command(:line_to, 3)
      26

      iex> command(:close_path)
      15
  """
  @spec command(:move_to | :line_to | :close_path, non_neg_integer()) :: integer()
  def command(command, count \\ 1)

  def command(:move_to, count), do: count <<< 3 ||| (@cmd_move_to &&& 0x7)
  def command(:line_to, count), do: count <<< 3 ||| (@cmd_line_to &&& 0x7)
  def command(:close_path, 1), do: 1 <<< 3 ||| (@cmd_close_path &&& 0x7)

  defp project(point, opts) do
    case Keyword.fetch(opts, :project) do
      {:ok, projection_fn} ->
        projection_fn.(point)

      :error ->
        point
    end
  end

  @doc """
  Zigzag encodes an
  [*ParameterInteger*](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#432-parameter-integers).

  Supports values greater than -2^31 and less than 2^31.

  Deprecated: Use `VectorTile.Coordinates.zigzag/1` instead.
  """
  @deprecated "Use VectorTile.Coordinates.zigzag/1 instead"
  defdelegate zigzag(value), to: VectorTile.Coordinates
end
