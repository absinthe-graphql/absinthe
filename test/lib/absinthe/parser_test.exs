defmodule Absinthe.ParserTest do
  use ExSpec, async: true

  it "parses a simple query" do
    assert {:ok, _} = Absinthe.parse("{ user(id: 2) { name } }")
  end

  it "fails gracefully" do
    assert {:error, _} = Absinthe.parse("{ user(id: 2 { name } }")
  end

  @reserved ~w(query mutation fragment on implements interface union scalar enum input extend null)
  it "can parse queries with arguments that are 'reserved words'" do
    @reserved
    |> Enum.each(fn
      arg ->
        assert {:ok, _} = Absinthe.parse("""
          mutation CreateThing($blah: Int!) {
            createThing(#{arg}: $blah) { clientThingId }
          }
          """)
    end)
  end

end
