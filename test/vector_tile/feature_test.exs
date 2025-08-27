defmodule VectorTile.FeatureTest do
  use ExUnit.Case, async: true

  alias VectorTile.Feature

  describe "zigzag/1" do
    test "supports specified number range" do
      assert Feature.zigzag(0) == 0
      assert Feature.zigzag(1) == 2
      assert Feature.zigzag(-1) == 1
      assert Feature.zigzag(2) == 4
      assert Feature.zigzag(-2) == 3
      assert Feature.zigzag(3) == 6
      assert Feature.zigzag(-3) == 5
      assert Feature.zigzag(2 ** 31 - 1) == 2 ** 32 - 2
      assert Feature.zigzag(-1 * (2 ** 31 - 1)) == 2 ** 32 - 3

      assert_raise FunctionClauseError, fn ->
        Feature.zigzag(2 ** 31)
      end

      assert_raise FunctionClauseError, fn ->
        Feature.zigzag(-1 * 2 ** 31)
      end
    end
  end
end
