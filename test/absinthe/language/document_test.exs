defmodule Absinthe.Language.DocumentTest do
  use Absinthe.Case, async: true

  alias Absinthe.Blueprint
  alias Absinthe.Language.Document
  alias Absinthe.Language.OperationDefinition

  @input """
  query MyQuery1 {
    thing(id: "1") {
      name
    }
  }
  query MyQuery2 {
    thing(id: "1") {
      name
    }
  }
  mutation MyMutation {
    thing(id: "1") {
      name
    }
  }

  """

  describe "get_operation/2" do
    test "given an existing operation name, returns the operation definition" do
      {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(@input)
      result = Document.get_operation(doc, "MyQuery2")
      assert %OperationDefinition{name: "MyQuery2", operation: :query} = result
    end

    test "given a non-existing operation name" do
      {:ok, %{input: doc}} = Absinthe.Phase.Parse.run(@input)
      result = Document.get_operation(doc, "DoesNotExist")
      assert nil == result
    end
  end

  describe "converting to Blueprint" do
    test "returns a Blueprint.t" do
      assert %Blueprint{} = ir("{ foo }")
      assert %Blueprint{} = ir("query { baz }")
      assert %Blueprint{} = ir("type Thing { name: String! }")
    end

    test "returns a Blueprint.t with the right number of operations" do
      rep = ir("{ foo } mutation Bar { bar } subscription Baz { baz }")
      assert length(rep.directives) == 0
      assert length(rep.operations) == 3
      assert length(rep.types) == 0
      assert length(rep.fragments) == 0
    end

    test "returns a Blueprint.t with the right number of types" do
      rep =
        """

          type Person
          @description(text: "A person object")
          {
            name: String
          }

          type Business { name: String}
          union Entity = Person | Business
          enum Purpose { BUSINESS PLEASURE }
        """
        |> ir

      assert length(rep.directives) == 0
      assert length(rep.operations) == 0
      assert length(rep.types) == 4
      assert length(rep.fragments) == 0
    end

    test "returns a Blueprint.t with the right number of fragments" do
      rep =
        """
        query {
          myItems {
            ... ItemFields
            ... NameField
          }
          otherItems {
            ... ItemFields
          }
        }
        fragment ItemFields on Item {
          count
        }
        fragment NameField on NamedThing {
          name
        }

        """
        |> ir

      assert length(rep.directives) == 0
      assert length(rep.operations) == 1
      assert length(rep.types) == 0
      assert length(rep.fragments) == 2
    end

    test "returns a Blueprint.t with the right number of directives" do
      rep = ir("directive @cs(if: Boolean!) on FIELD")
      assert length(rep.directives) == 1
      assert length(rep.operations) == 0
      assert length(rep.types) == 0
      assert length(rep.fragments) == 0
    end
  end

  describe "converting to Blueprint for Schema" do
    @idl """
    enum Episode { NEWHOPE, EMPIRE, JEDI }

    scalar Time

    interface Character {
      id: String!
      name: String
      friends: [Character]
      appearsIn: [Episode]
    }

    type Human implements Character {
      id: String!
      name: String
      friends: [Character]
      appearsIn: [Episode]
      homePlanet: String
    }

    type Droid implements Character {
      id: String!
      name: String
      friends: [Character]
      appearsIn: [Episode]
      primaryFunction: String
    }

    type Query {
      hero(episode: Episode): Character
      human(id: String!): Human
      droid(id: String!): Droid
    }

    type Foo {
      name: String
    }

    type Bar {
      name: String
    }

    input Profile {
      name: String!
      age: Int = 18
    }

    union Baz = Foo | Bar
    """

    test "creates the correct number of types" do
      rep = ir(@idl)
      assert length(rep.types) == 10
    end
  end

  def ir(input) do
    {:ok, blueprint, _} =
      Absinthe.Pipeline.run(input, [Absinthe.Phase.Parse, Absinthe.Phase.Blueprint])

    blueprint
  end
end
