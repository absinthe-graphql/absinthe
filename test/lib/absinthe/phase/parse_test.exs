defmodule Absinthe.Phase.ParseTest do
  use Absinthe.Case, async: true

  it "parses a simple query" do
    assert {:ok, _} = run("{ user(id: 2) { name } }")
  end

  it "fails gracefully" do
    assert {:error, _} = run("{ user(id: 2 { name } }")
  end

  @reserved ~w(query mutation fragment on implements interface union scalar enum input extend null)
  it "can parse queries with arguments and variables that are 'reserved words'" do
    @reserved
    |> Enum.each(fn
      name ->
        assert {:ok, _} = run("""
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
    assert {:ok, _} = run(@query)
  end

  @query """
  mutation {
    createUser(name: "Владимир") {
      id
    }
  }
  """
  it "can parse UTF-8" do
    assert {:ok, _} = run(@query)
  end

  @query """
  query Something($enum: String!) {
    doSomething(directive: "thing") {
      id
    }
    doSomething(directive: "thing") @schema(object: $enum) {
      id
    }
  }
  """
  it "can parse identifiers in different contexts" do
    assert {:ok, _} = run(@query)
  end

  @query """
  query Something($on: String!) {
    on(on: "thing") {
      id
    }
    doSomething(on: "thing") @on(on: $on) {
      id
    }
  }
  """
  it "can parse 'on' in different contexts" do
    assert {:ok, _} = run(@query)
  end

  @query ~S"""
  mutation {
    item(data: "{\"foo\": \"bar\"}") {
      id
      data
    }
  }
  """
  it "can parse escaped strings as inputs" do
    assert {:ok, res} = run(@query)
    path = [
      Access.key(:definitions),
      Access.at(0),
      Access.key(:selection_set),
      Access.key(:selections),
      Access.at(0),
      Access.key(:arguments),
      Access.at(0),
      Access.key(:value),
      Access.key(:value)
    ]
    assert ~s({"foo": "bar"}) == get_in(res, path)
  end


  @query ~S"""
  mutation {
    item(data: "foo\nbar") {
      id
      data
    }
  }
  """
  it "can parse escaped characters in inputs" do
    assert {:ok, res} = run(@query)
    path = [
      Access.key(:definitions),
      Access.at(0),
      Access.key(:selection_set),
      Access.key(:selections),
      Access.at(0),
      Access.key(:arguments),
      Access.at(0),
      Access.key(:value),
      Access.key(:value)
    ]
    assert ~s(foo\nbar) == get_in(res, path)
  end

  @query ~S"""
  mutation {
    item(data: "\" \\ \/ \b \f \n \r \t \u00F3 \u00f3 \u04F9") {
      id
      data
    }
  }
  """
  it "can parse all types of characters escaped according to GraphQL spec as inputs" do
    assert {:ok, res} = run(@query)
    path = [
      Access.key(:definitions),
      Access.at(0),
      Access.key(:selection_set),
      Access.key(:selections),
      Access.at(0),
      Access.key(:arguments),
      Access.at(0),
      Access.key(:value),
      Access.key(:value)
    ]

    assert ~s(\" \\ \/ \b \f \n \r \t ó ó ӹ) == get_in(res, path)
  end

  def run(input) do
    Absinthe.Phase.Parse.run(input)
  end



end
