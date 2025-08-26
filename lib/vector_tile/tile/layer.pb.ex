defmodule VectorTile.Tile.Layer do
  @moduledoc """
  Represents a [layer](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#41-layers) in a vector tile which
  can contain multiple [`Feature`](`VectorTile.Tile.Feature`)s.

  ## Example

      iex> layer = %VectorTile.Tile.Layer{
      ...>   name: "clusters",
      ...>   version: 2
      ...> }
  """

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  field :version, 15, required: true, type: :uint32, default: 1
  field :name, 1, required: true, type: :string
  field :features, 2, repeated: true, type: VectorTile.Tile.Feature
  field :keys, 3, repeated: true, type: :string
  field :values, 4, repeated: true, type: VectorTile.Tile.Value
  field :extent, 5, optional: true, type: :uint32, default: 4096

  extensions [{16, Protobuf.Extension.max()}]

  def transform_module(), do: VectorTile.Tile.LayerTransformer

  @doc """
  Adds a feature to the layer. Optionally handles feature attributes, which are added to the layer's `keys` and
  `values` and referenced by the feature's `tags`.

  Attributes with `nil` values are skipped, as they can't be represented.

  Use this method over simply adding a feature to `layer.features` for correct handling of the feature's `tags`
  (pointers into the layer's `keys` and `values` lists), including deduplication of existing keys and values as per
  [Feature Attributes](https://github.com/mapbox/vector-tile-spec/tree/master/2.1#44-feature-attributes).

  This method is optimized for a potential high number of unique attribute values, but expects a rather small number of
  unique attribute keys. To achieve good performance, the layer's `values` list will only be built in the `encode`-hook,
  while the `keys` list is built immediately as features/attributes are added.

  ## Example

      iex> layer = %VectorTile.Tile.Layer{}
      iex> feature = %VectorTile.Tile.Feature{}
      iex> VectorTile.Tile.Layer.add_feature(layer, feature, color: "red", size: 42, count: 42)
      %VectorTile.Tile.Layer{
        features: [
          %VectorTile.Tile.Feature{
            tags: [0, 0, 1, 1, 2, 1]
            # ...
          }
        ],
        keys: ["color", "size", "count"],
        values: [
          %VectorTile.Tile.Value{string_value: "red"},
          %VectorTile.Tile.Value{int_value: 42}
        ]
        # ...
      }
  """
  @spec add_feature(t(), VectorTile.Tile.Feature.t(), map() | Keyword.t()) :: t()
  def add_feature(layer, feature, attributes \\ %{}) do
    {layer, feature} =
      Enum.reduce(attributes, {layer, feature}, fn
        # Skip attributes with nil values as they can't be represented.
        {_key, nil}, acc ->
          acc

        {key, value}, {layer, feature} ->
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

          # Add value to the values cache (if not already present) and remember its index. Converting from `__values__` to
          # the actual `values` list is done by LayerTransformer's `encode` hook.
          value_cache = Map.get(layer, :__values__, %{})
          {value_cache, value_index} = get_cached_or_add(value_cache, value)
          layer = Map.put(layer, :__values__, value_cache)

          feature = %{feature | tags: feature.tags ++ [key_index, value_index]}

          {layer, feature}
      end)

    Map.update(layer, :features, [feature], fn features ->
      [feature | features]
    end)
  end

  defp get_cached_or_add(value_cache, value) do
    case Map.fetch(value_cache, value) do
      {:ok, value_index} ->
        {value_cache, value_index}

      :error ->
        value_index = map_size(value_cache)
        value_cache = Map.put(value_cache, value, value_index)

        {value_cache, value_index}
    end
  end
end
