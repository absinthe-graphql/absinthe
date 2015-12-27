defmodule Absinthe.Type.TypesTest do
  use ExSpec, async: true

  alias Absinthe.Schema

  it "finds custom types" do
    types = Things.schema.types |> Map.keys

    assert Enum.member?(types, :thing)
    assert Enum.member?(types, :input_thing)
  end

end
