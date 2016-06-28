defmodule Absinthe.IRTest do
  use Absinthe.Case, async: true

  alias Absinthe.IR

  describe '.from_ast' do

    test 'returns an IR struct' do
      assert %IR{} = ir("{ foo }")
      assert %IR{} = ir("query { baz }")
      assert %IR{} = ir("type Thing { name: String! }")
    end

    test 'returns an IR struct with the right number of operations' do
      rep = ir("{ foo } mutation Bar { bar } subscription Baz { baz }")
      assert length(rep.directives) == 0
      assert length(rep.operations) == 3
      assert length(rep.types) == 0
    end

    test 'returns an IR struct with the right number of types' do
      rep = """

        type Person
        @description(text: "A person object")
        {
          name: String
        }

        type Business { name: String}
        union Entity = Person | Business
        enum Purpose { BUSINESS PLEASURE }
      """ |> ir
      assert length(rep.directives) == 0
      assert length(rep.operations) == 0
      assert length(rep.types) == 4
    end


    test 'returns an IR struct with the right number of directives' do
      rep = ir("directive @cs(if: Boolean!) on FIELD")
      assert length(rep.directives) == 1
      assert length(rep.operations) == 0
      assert length(rep.types) == 0
    end

  end

  describe '.from_ast for IDL' do

    @idl """
    enum Episode { NEWHOPE, EMPIRE, JEDI }

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

    union Baz = Foo | Bar
    """

    test "creates the correct number of types" do
      rep = ir(@idl)
      assert length(rep.types) == 8
    end

  end

  def ir(input) do
    Absinthe.parse!(input)
    |> Absinthe.IR.from_ast
  end

end
