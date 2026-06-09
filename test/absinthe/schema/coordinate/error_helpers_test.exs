defmodule Absinthe.Schema.Coordinate.ErrorHelpersTest do
  use Absinthe.Case, async: true

  alias Absinthe.Schema.Coordinate.ErrorHelpers

  describe "coordinate_for/1-3" do
    test "generates type coordinate" do
      assert ErrorHelpers.coordinate_for("User") == "User"
    end

    test "generates field coordinate" do
      assert ErrorHelpers.coordinate_for("User", "email") == "User.email"
    end

    test "generates argument coordinate" do
      assert ErrorHelpers.coordinate_for("Query", "user", "id") == "Query.user(id:)"
    end

    test "generates directive coordinate" do
      assert ErrorHelpers.coordinate_for(:directive, "deprecated") == "@deprecated"
    end

    test "generates directive argument coordinate" do
      assert ErrorHelpers.coordinate_for(:directive, "deprecated", "reason") == "@deprecated(reason:)"
    end
  end

  describe "put_coordinate/2-4" do
    test "adds coordinate to error map" do
      error = %{message: "Field is deprecated"}

      assert ErrorHelpers.put_coordinate(error, "User") ==
               %{message: "Field is deprecated", coordinate: "User"}

      assert ErrorHelpers.put_coordinate(error, "User", "oldField") ==
               %{message: "Field is deprecated", coordinate: "User.oldField"}

      assert ErrorHelpers.put_coordinate(error, "Query", "user", "id") ==
               %{message: "Field is deprecated", coordinate: "Query.user(id:)"}
    end
  end

  describe "with_coordinate/2-4" do
    test "formats message with coordinate prefix" do
      assert ErrorHelpers.with_coordinate("is deprecated", "User") ==
               "[User] is deprecated"

      assert ErrorHelpers.with_coordinate("is deprecated", "User", "oldField") ==
               "[User.oldField] is deprecated"

      assert ErrorHelpers.with_coordinate("is required", "Query", "user", "id") ==
               "[Query.user(id:)] is required"
    end
  end
end
