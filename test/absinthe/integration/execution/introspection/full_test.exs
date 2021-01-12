defmodule Elixir.Absinthe.Integration.Execution.Introspection.FullTest do
  use Absinthe.Case, async: true

  test "scenario #1" do
    result = Absinthe.Schema.introspect(Absinthe.Fixtures.ContactSchema)
    {:ok, %{data: %{"__schema" => schema}}} = result

    assert schema["description"] == "Represents a schema"
    assert schema["queryType"]
    assert schema["mutationType"]
    assert schema["subscriptionType"]
    assert schema["types"]
    assert schema["directives"]
  end

  defmodule MiddlewareSchema do
    use Absinthe.Schema

    query do
    end

    def middleware(_, _, _) do
      raise "this should not be called when introspecting"
    end
  end

  test "middleware callback does not apply to introspection fields" do
    assert Absinthe.Schema.introspect(MiddlewareSchema)
  end
end
