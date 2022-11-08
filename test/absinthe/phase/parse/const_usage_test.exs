defmodule Absinthe.Phase.Parse.ConstUsageTest do
  use Absinthe.Case, async: true

  @moduletag :parser

  describe "composed constants" do
    test "list in a constant location can be empty " do
      result =
        """
          schema @feature(name: []){
            query: Query
          }
        """
        |> run

      assert {:ok, _} = result
    end

    test "list in a constant location cannot contain variables " do
      result =
        """
          schema @feature(name: [$name]){
            query: Query
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "input object in a constant location cannot contain variables " do
      result =
        """
          schema @feature(name: {a: $name}){
            query: Query
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end
  end

  describe "schema parsing" do
    test "schema definition directive arguments are constant" do
      result =
        """
          schema @feature(name: $name){
            query: Query
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "scalar definition directive arguments are constant" do
      result =
        """
          scalar SweetScalar @feature(name: $name)
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "type definition directive arguments are constant" do
      result =
        """
          type Comment @feature(name: $name) {
            text: String
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "field definition directive arguments are constant" do
      result =
        """
          type Comment {
            text: String @feature(name: $name)
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "field arguments directive arguments are constant" do
      result =
        """
          type Comment {
            text(arg: String @feature(name: $name)): String
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "interface type definition directive arguments are constant" do
      result =
        """
          interface NamedEntity @feature(name: $name) {
            text: String
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "union type definition directive arguments are constant" do
      result =
        """
          union SearchResult @feature(name: $name) = Photo | Person
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "enum type definition directive arguments are constant" do
      result =
        """
          enum Direction @feature(name: $name){
            NORTH
            EAST
            SOUTH
            WEST
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "enum value definition directive arguments are constant" do
      result =
        """
          enum Direction {
            NORTH @feature(name: $name)
            EAST
            SOUTH
            WEST
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "input object type definition directive arguments are constant" do
      result =
        """
          input Point2D @feature(name: $name){
            x: Float
            y: Float
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end
  end

  describe "document parsing" do
    test "variable definition default values are constant" do
      result =
        """
          query getProfile($devicePicSize: Int = $var) {
            name
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end

    test "variable definition directive arguments are constant" do
      result =
        """
          query getProfile($devicePicSize: Int @feature(name: $name)) {
            name
          }
        """
        |> run

      assert {:error, [%{message: "syntax error before: '$'"}]} = result
    end
  end

  def run(input) do
    case Absinthe.Phase.Parse.run(input) do
      {:error, blueprint} -> {:error, blueprint.execution.validation_errors}
      {:ok, blueprint} -> {:ok, blueprint}
    end
  end
end
