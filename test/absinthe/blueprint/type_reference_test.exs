defmodule Absinthe.Blueprint.TypeReferenceTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint
  @moduletag :f

  describe ".unwrap of Name" do
    test "is left intact" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      assert Blueprint.TypeReference.unwrap(name) == name
    end
  end

  describe ".unwrap of List" do
    test "extracts the inner name" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      list = %Blueprint.TypeReference.List{of_type: name}
      assert Blueprint.TypeReference.unwrap(list) == name
    end

    test "extracts the inner name, even when multiple deep" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      list_1 = %Blueprint.TypeReference.List{of_type: name}
      list_2 = %Blueprint.TypeReference.List{of_type: list_1}
      assert Blueprint.TypeReference.unwrap(list_2) == name
    end
  end

  describe ".unwrap of NonNull" do
    test "extracts the inner name" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      list = %Blueprint.TypeReference.NonNull{of_type: name}
      assert Blueprint.TypeReference.unwrap(list) == name
    end

    test "extracts the inner name, even when multiple deep" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      non_null = %Blueprint.TypeReference.NonNull{of_type: name}
      list = %Blueprint.TypeReference.List{of_type: non_null}
      assert Blueprint.TypeReference.unwrap(list) == name
    end
  end

  describe "name/1 of Name" do
    test "returns type name" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      assert Blueprint.TypeReference.name(name) == "Foo"
    end
  end

  describe "name/1 of List" do
    test "returns type name in list" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      list = %Blueprint.TypeReference.List{of_type: name}
      assert Blueprint.TypeReference.name(list) == "[Foo]"
    end

    test "returns type name, in multiple lists" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      list_1 = %Blueprint.TypeReference.List{of_type: name}
      list_2 = %Blueprint.TypeReference.List{of_type: list_1}
      assert Blueprint.TypeReference.name(list_2) == "[[Foo]]"
    end
  end

  describe "name/1 of NonNull" do
    test "returns non null type name" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      list = %Blueprint.TypeReference.NonNull{of_type: name}
      assert Blueprint.TypeReference.name(list) == "Foo!"
    end

    test "returns nested non null type name" do
      name = %Blueprint.TypeReference.Name{name: "Foo"}
      non_null = %Blueprint.TypeReference.NonNull{of_type: name}
      list = %Blueprint.TypeReference.List{of_type: non_null}
      assert Blueprint.TypeReference.name(list) == "[Foo!]"
    end
  end
end
