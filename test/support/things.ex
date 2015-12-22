defmodule Things do

  use Absinthe.Type
  alias Absinthe.Type

  def schema do
    %Type.Schema{
      mutation: %Type.ObjectType{
        name: "RootMutation",
        fields: fields(
          update_thing: [
            type: thing_type,
            args: args(
              id: [type: non_null(Type.Scalar.string)],
              thing: [type: non_null(input_thing_type)]
            ),
            resolve: fn
              %{id: id, thing: %{value: val}}, _ ->
                found = things |> Map.get(id)
                {:ok, %{found | value: val}}
              %{id: id, thing: fields}, _ ->
                found = things |> Map.get(id)
                {:ok, found |> Map.merge(fields)}
            end
          ]
        )
      },
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
                type: non_null(Type.Scalar.string)
              ],
              deprecated_arg: deprecate([
                description: "This is a deprecated arg",
                type: Type.Scalar.string
              ]),
              deprecated_non_null_arg: deprecate([
                description: "This is a non-null deprecated arg",
                type: non_null(Type.Scalar.string)
              ]),
              deprecated_arg_with_reason: deprecate([
                description: "This is a deprecated arg with a reason",
                type: Type.Scalar.string
              ], reason: "reason"),
              deprecated_non_null_arg_with_reason: deprecate([
                description: "This is a non-null deprecated arg with a reasor",
                type: non_null(Type.Scalar.string)
              ], reason: "reason"),
            ),
            resolve: fn
              (%{id: id}, _) ->
                {:ok, things |> Map.get(id)}
            end
          ],
          deprecated_thing: deprecate([
            type: thing_type,
            args: args(
              id: [
                description: "id of the thing",
                type: non_null(Type.Scalar.string)
              ]
            ),
            resolve: fn
              (%{id: id}, _) ->
                {:ok, things |> Map.get(id)}
            end
          ]),
          deprecated_thing_with_reason: deprecate([
            type: thing_type,
            args: args(
              id: [
                description: "id of the thing",
                type: non_null(Type.Scalar.string)
              ]
            ),
            resolve: fn
              (%{id: id}, _) ->
                {:ok, things |> Map.get(id)}
            end
          ], reason: "use `thing' instead")
        )
      }
    }
  end

  defp input_thing_type do
    %Type.InputObjectType{
      name: "Thing Input Type",
      description: "A thing as input",
      fields: fields(
        value: [type: Type.Scalar.integer],
        deprecated_field: deprecate([type: Type.Scalar.string]),
        deprecated_field_with_reason: deprecate([type: Type.Scalar.string], reason: "reason"),
        deprecated_non_null_field: deprecate([type: non_null(Type.Scalar.string)]),
        deprecated_non_null_field_with_reason: deprecate([type: Type.Scalar.string], reason: "reason")
      )
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
        value: [
          type: Type.Scalar.integer,
          description: "The value of the thing"
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
      "foo" => %{id: "foo", name: "Foo", value: 4},
      "bar" => %{id: "bar", name: "Bar", value: 5}
     }
  end

end
