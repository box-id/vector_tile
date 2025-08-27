# VectorTile

[![Hex.pm Version](https://img.shields.io/hexpm/v/vector_tile)](https://hex.pm/packages/vector_tile)
[![Hexdocs](https://img.shields.io/badge/HexDocs-8A2BE2)](https://hexdocs.pm/vector_tile)
[![Static Badge](https://img.shields.io/badge/Changelog-0398fc)](https://github.com/box-id/vector_tile/releases)

Implementation of the [Vector Tile Spec](https://github.com/mapbox/vector-tile-spec/tree/master/2.1), version 2.1. This
package allows you to efficiently build vector tiles including layers and features with geometry and encode them to
protobuf.

## Usage

The following sample shows how to create a simple vector tile with one layer and one point feature:

```elixir
alias VectorTile.{
  Feature,
  Layer,
  Tile
}

# Create an empty named layer
layer = %Layer{
  name: "clusters",
  version: 2
}

# Add a feature with attributes
layer = Layer.add_feature(
  layer,
  %Feature{
    type: :POINT,
    # "Raw" geometry specification as per https://github.com/mapbox/vector-tile-spec/tree/master/2.1#43-geometry-encoding
    geometry: [9, 128, 128]
  },
  count: 42,
  size: "large"
)

# Construct tile
tile = %Tile{
  layers: [layer]
}

# Encode to protobuf bytes
Tile.encode(tile)
```

## Installation

```elixir
def deps do
  [
    {:vector_tile, "~> 0.1.0"}
  ]
end
```
