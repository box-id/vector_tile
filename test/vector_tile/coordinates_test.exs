defmodule VectorTile.CoordinatesTest do
  use ExUnit.Case, async: true

  alias VectorTile.Coordinates

  doctest(Coordinates, import: true)

  describe "zigzag/1" do
    test "supports specified number range" do
      assert Coordinates.zigzag(0) == 0
      assert Coordinates.zigzag(1) == 2
      assert Coordinates.zigzag(-1) == 1
      assert Coordinates.zigzag(2) == 4
      assert Coordinates.zigzag(-2) == 3
      assert Coordinates.zigzag(3) == 6
      assert Coordinates.zigzag(-3) == 5
      assert Coordinates.zigzag(2 ** 31 - 1) == 2 ** 32 - 2
      assert Coordinates.zigzag(-1 * (2 ** 31 - 1)) == 2 ** 32 - 3

      assert_raise FunctionClauseError, fn ->
        Coordinates.zigzag(2 ** 31)
      end

      assert_raise FunctionClauseError, fn ->
        Coordinates.zigzag(-1 * 2 ** 31)
      end
    end
  end
end
