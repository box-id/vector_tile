defmodule VectorTile.ValueTest do
  use ExUnit.Case, async: true

  alias VectorTile.Value

  describe "from_plain/1" do
    test "creates integer value" do
      assert %Value{int_value: 42} = Value.from_plain(42)
    end

    test "creates string value" do
      assert %Value{string_value: "hello"} = Value.from_plain("hello")
    end

    test "creates boolean value" do
      assert %Value{bool_value: true} = Value.from_plain(true)
    end

    test "creates double value" do
      assert %Value{double_value: 3.14} = Value.from_plain(3.14)
    end
  end
end
