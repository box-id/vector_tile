defmodule VectorTile.LayerTest do
  use ExUnit.Case, async: true

  alias VectorTile.Tile.{
    Feature,
    Layer
  }

  describe "add_feature/3" do
    test "adds a feature with properties to the layer" do
      layer = %Layer{name: "clusters"}
      feature = %Feature{type: :POINT, geometry: [9, 0, 0]}
      properties = %{count: 12, type: "cluster"}

      layer = Layer.add_feature(layer, feature, properties)

      assert length(layer.features) == 1
      assert layer == encode(layer)

      feature = Enum.at(layer.features, 0)

      assert properties == feature_properties(feature, layer)
    end

    test "repeated property keys & values are deduplicated" do
      layer = %Layer{name: "clusters"}
      feature1 = %Feature{id: 1, type: :POINT, geometry: [9, 0, 0]}
      feature2 = %Feature{id: 2, type: :POINT, geometry: [9, 0, 0]}
      properties1 = %{count: 13, type: "cluster"}
      properties2 = %{count: 12, type: "cluster"}

      layer =
        layer
        |> Layer.add_feature(feature1, properties1)
        |> Layer.add_feature(feature2, properties2)

      assert length(layer.features) == 2
      assert length(layer.keys) == 2
      assert length(layer.values) == 3
      assert layer == encode(layer)

      # Note inverse order of features
      feature1 = Enum.at(layer.features, 1)
      feature2 = Enum.at(layer.features, 0)

      assert properties1 == feature_properties(feature1, layer)
      assert properties2 == feature_properties(feature2, layer)
    end
  end

  defp encode(%{__struct__: module} = data) do
    data
    |> Protobuf.encode()
    |> Protobuf.decode(module)
  end

  defp feature_properties(feature, layer) do
    key_tags = feature.tags |> Enum.take_every(2)
    value_tags = feature.tags |> Enum.drop(1) |> Enum.take_every(2)

    Enum.zip_reduce(key_tags, value_tags, %{}, fn key_index, value_index, acc ->
      key =
        layer.keys
        |> Enum.at(key_index)
        |> String.to_atom()

      value =
        layer.values
        |> Enum.at(value_index)
        |> Map.from_struct()
        |> Map.drop([:__pb_extensions__, :__unknown_fields__])
        |> Enum.find_value(fn {_key, v} -> v end)

      Map.put(acc, key, value)
    end)
  end
end
