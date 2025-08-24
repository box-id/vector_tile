defmodule VectorTile.Tile.Value do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto2

  field :string_value, 1, optional: true, type: :string, json_name: "stringValue"
  field :float_value, 2, optional: true, type: :float, json_name: "floatValue"
  field :double_value, 3, optional: true, type: :double, json_name: "doubleValue"
  field :int_value, 4, optional: true, type: :int64, json_name: "intValue"
  field :uint_value, 5, optional: true, type: :uint64, json_name: "uintValue"
  field :sint_value, 6, optional: true, type: :sint64, json_name: "sintValue"
  field :bool_value, 7, optional: true, type: :bool, json_name: "boolValue"

  extensions [{8, Protobuf.Extension.max()}]

  def from_plain(value) when is_integer(value) do
    struct!(__MODULE__, int_value: value)
  end

  def from_plain(value) when is_float(value) do
    # Elixir only has double precision floats
    struct!(__MODULE__, double_value: value)
  end

  def from_plain(value) when is_binary(value) do
    struct!(__MODULE__, string_value: value)
  end

  def from_plain(value) when is_boolean(value) do
    struct!(__MODULE__, bool_value: value)
  end
end
