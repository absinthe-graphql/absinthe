defmodule Things do

  use ExGraphQL.Type
  alias ExGraphQL.Type

  def schema do
    %Type.Schema{
      query: %Type.ObjectType{
        name: "RootQuery",
        fields: fields(
          bad_resolution: [
            type: thing_type,
            resolve: fn(_, _) ->
              :not_expected
            end
          ],
          number: [
            type: Type.Scalar.string,
            args: args(
              val: [type: non_null(Type.Scalar.integer)]
            ),
            resolve: fn
              %{val: v} -> v |> to_string
            end
          ],
          thingByContext: [
            type: thing_type,
            resolve: fn
              (_, %{context: %{thing: id}}) -> {:ok, things |> Map.get(id)}
              (_, _) -> {:error, "No :id context provided"}
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
            resolve: fn
              (%{id: id}, _) ->
                {:ok, things |> Map.get(id)}
            end
          ]
        )
      }
    }
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
          resolve: fn (_, %{resolution: %{target: %{id: id}}}) ->
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

end
