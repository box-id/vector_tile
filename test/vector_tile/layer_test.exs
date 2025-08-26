defmodule VectorTile.LayerTest do
  use ExUnit.Case, async: true

  alias VectorTile.Tile.{
    Feature,
    Layer
  }

  describe "add_feature/3" do
    test "adds a feature without attributes to the layer" do
      layer = %Layer{name: "clusters"}
      feature = %Feature{type: :POINT, geometry: [9, 0, 0]}

      layer =
        layer
        |> Layer.add_feature(feature)
        |> encode()

      assert length(layer.features) == 1

      feature = Enum.at(layer.features, 0)
      assert feature == encode(feature)
    end

    test "adds a feature with attributes to the layer" do
      layer = %Layer{name: "clusters"}
      feature = %Feature{type: :POINT, geometry: [9, 0, 0]}
      attributes = %{count: 12, type: "cluster"}

      layer =
        layer
        |> Layer.add_feature(feature, attributes)
        |> encode()

      assert length(layer.features) == 1

      feature = Enum.at(layer.features, 0)

      assert attributes == feature_attributes(feature, layer)
    end

    test "repeated attribute keys & values are deduplicated" do
      layer = %Layer{name: "clusters"}
      feature_1 = %Feature{id: 1, type: :POINT, geometry: [9, 0, 0]}
      feature_2 = %Feature{id: 2, type: :POINT, geometry: [9, 0, 0]}
      attributes_1 = %{count: 13, type: "cluster"}
      attributes_2 = %{count: 12, type: "cluster"}

      layer =
        layer
        |> Layer.add_feature(feature_1, attributes_1)
        |> Layer.add_feature(feature_2, attributes_2)
        |> encode()

      assert length(layer.features) == 2
      assert length(layer.keys) == 2
      assert length(layer.values) == 3

      # Note inverse order of features
      feature_1 = Enum.at(layer.features, 1)
      feature_2 = Enum.at(layer.features, 0)

      assert attributes_1 == feature_attributes(feature_1, layer)
      assert attributes_2 == feature_attributes(feature_2, layer)
    end

    test "skips attributes with nil values" do
      layer = %Layer{name: "clusters"}
      feature = %Feature{type: :POINT, geometry: [9, 0, 0]}
      attributes = %{count: 12, type: "cluster", description: nil}

      layer =
        Layer.add_feature(layer, feature, attributes)
        |> encode()

      feature = Enum.at(layer.features, 0)
      assert Map.delete(attributes, :description) == feature_attributes(feature, layer)
    end
  end

  defp encode(%{__struct__: module} = data) do
    data
    |> Protobuf.encode()
    |> Protobuf.decode(module)
  end

  # Convert feature tags back to a map of attributes
  defp feature_attributes(feature, layer) do
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
