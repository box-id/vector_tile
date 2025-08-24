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

  @doc """
  Adds a feature to the layer. Optionally handles feature properties, which will be added to the layer's `keys` and
  `values`.

  Use this method over simply adding a feature to `layer.features` for correct handling of the feature's `tags` (
  pointers into the layer's `keys` and `values` lists), including deduplication of existing keys and values.
  """
  def add_feature(layer, feature, properties \\ %{}) do
    {layer, feature} =
      Enum.reduce(properties, {layer, feature}, fn {key, value}, {layer, feature} ->
        # support atom keys
        key = to_string(key)

        key_index = Enum.find_index(layer.keys, &(&1 == key))

        {layer, key_index} =
          if is_nil(key_index) do
            layer = %{layer | keys: layer.keys ++ [key]}
            key_index = length(layer.keys) - 1

            {layer, key_index}
          else
            {layer, key_index}
          end

        value = VectorTile.Tile.Value.from_plain(value)
        value_index = Enum.find_index(layer.values, &(&1 == value))

        {layer, value_index} =
          if is_nil(value_index) do
            layer = %{layer | values: layer.values ++ [value]}
            value_index = length(layer.values) - 1

            {layer, value_index}
          else
            {layer, value_index}
          end

        feature = %{feature | tags: feature.tags ++ [key_index, value_index]}

        {layer, feature}
      end)

    Map.update(layer, :features, [feature], fn features ->
      [feature | features]
    end)
  end
end
