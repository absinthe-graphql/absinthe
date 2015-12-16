defmodule ExGraphQLTest do
  use ExSpec, async: true
  use ExGraphQL.Type
  alias ExGraphQL.Type

  it "can run without validation" do
    schema = StarWars.Schema.schema
    query = """
      query HeroNameQuery {
        hero {
          name
        }
      }
    """
    # This does not actually resolve data yet
    assert {:ok, %{"data" => %{"hero" => %{"name" => "R2-D2"}}, "errors" => []}} = ExGraphQL.run(schema, query, validate: false)
  end

  defp thing_type do
    %Type.ObjectType{
      name: "Thing",
      description: "A thing",
      fields: fields(
        id: [
          type: %Type.NonNull{of_type: Type.Scalar.string},
          description: "The ID of the thing"
        ],
        name: [
          type: Type.Scalar.string,
          description: "The name of the thing"
        ],
        other_thing: [
          type: thing_type,
          resolve: fn (_, _exe, %{target: %{id: id}}) ->
            case id do
              "foo" -> {:ok, things |> Map.get("bar")}
              "bar" -> {:ok, things |> Map.get("foo")}
            end
          end
        ]
      )
    }
  end

  defp things do
    %{
      "foo" => %{id: "foo", name: "Foo"},
      "bar" => %{id: "bar", name: "Bar"}
     }
  end

  defp simple_schema do
    %Type.Schema{
      query: %Type.ObjectType{
        name: "RootQuery",
        fields: fields(
          bad_resolution: [
            type: thing_type,
            resolve: fn(_args, _exe, _res) ->
              :not_expected
            end
          ],
          thing: [
            type: thing_type,
            args: args(
              id: [
                description: "id of the thing",
                type: %Type.NonNull{of_type: Type.Scalar.string}
              ]
            ),
            resolve: fn (%{"id" => id}, _exe, _res) ->
              {:ok, things |> Map.get(id)}
            end
          ]
        )
      }
    }
  end

  it "can do a simple query" do
    query = """
    query GimmeFoo {
      thing(id: "foo") {
        name
      }
    }
    """
    assert {:ok, %{"data" => %{"thing" => %{"name" => "Foo"}}, "errors" => []}} = ExGraphQL.run(simple_schema, query, validate: false)
  end

  it "can identify a bad field" do
    query = """
    {
      thing(id: "foo") {
        name
        bad
      }
    }
    """
    assert {:ok, %{"data" => %{"thing" => %{"name" => "Foo"}}, "errors" => [%{"message" => "No field 'bad'", "locations" => [%{"line" => 4}]}]}} = ExGraphQL.run(simple_schema, query, validate: false)
  end

  it "gives nice errors for bad resolutions" do
    query = """
    {
      bad_resolution
    }
    """
    assert {:ok, %{"data" => %{},
                   "errors" => [%{"message" => "Invalid value resolved for field 'bad_resolution'", "locations" => _}]}} = ExGraphQL.run(simple_schema, query, validate: false)
  end

  it "returns the correct results for an alias" do
    query = """
    query GimmeFooByAlias {
      widget: thing(id: "foo") {
        name
      }
    }
    """
    assert {:ok, %{"data" => %{"widget" => %{"name" => "Foo"}}, "errors" => []}} = ExGraphQL.run(simple_schema, query, validate: false)
  end

  it "returns nested objects" do
    query = """
    query GimmeFooWithOtherThing {
      thing(id: "foo") {
        name
        other_thing {
          name
        }
      }
    }
    """
    assert {:ok, %{"data" => %{"thing" => %{"name" => "Foo", "other_thing" => %{"name" => "Bar"}}}, "errors" => []}} = ExGraphQL.run(simple_schema, query, validate: false)
  end

end
