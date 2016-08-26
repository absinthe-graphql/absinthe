defmodule Absinthe.ParserTest do
  use Absinthe.Case, async: true

  it "parses a simple query" do
    assert {:ok, _} = Absinthe.parse("{ user(id: 2) { name } }")
  end

  it "fails gracefully" do
    assert {:error, _} = Absinthe.parse("{ user(id: 2 { name } }")
  end

  @reserved ~w(query mutation fragment on implements interface union scalar enum input extend null)
  it "can parse queries with arguments and variables that are 'reserved words'" do
    @reserved
    |> Enum.each(fn
      name ->
        assert {:ok, _} = Absinthe.parse("""
        mutation CreateThing($#{name}: Int!) {
          createThing(#{name}: $#{name}) { clientThingId }
        }
        """)
    end)
  end

  @query """
  mutation {
    likeStory(storyID: 12345) {
      story {
        likeCount
      }
    }
  }
  subscription {
    viewer { likes }
  }
  """
  it "can parse mutations and subscriptions without names" do
    assert {:ok, _} = Absinthe.parse(@query)
  end

  @query """
  mutation {
    createUser(name: "Владимир") {
      id
    }
  }
  """
  it "can parse UTF-8" do
    assert {:ok, _} = Absinthe.parse(@query)
  end


end
