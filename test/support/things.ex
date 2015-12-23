defmodule Things do

  use Absinthe.Schema
  alias Absinthe.Type

  @db %{
    "foo" => %{id: "foo", name: "Foo", value: 4},
    "bar" => %{id: "bar", name: "Bar", value: 5}
  }

  def mutation do
    %Type.ObjectType{
      name: "RootMutation",
      fields: fields(
        update_thing: [
          type: :thing,
          args: args(
            id: [type: non_null(:string)],
            thing: [type: non_null(:input_thing)]
          ),
          resolve: fn
            %{id: id, thing: %{value: val}}, _ ->
              found = @db |> Map.get(id)
            {:ok, %{found | value: val}}
            %{id: id, thing: fields}, _ ->
              found = @db |> Map.get(id)
            {:ok, found |> Map.merge(fields)}
          end
        ]
      )
    }
  end

  def query do
    %Type.ObjectType{
      fields: fields(
        bad_resolution: [
          type: :thing,
          resolve: fn(_, _) ->
            :not_expected
          end
        ],
        number: [
          type: :string,
          args: args(
            val: [type: non_null(:int)]
          ),
          resolve: fn
            %{val: v} -> v |> to_string
          end
        ],
        thingByContext: [
          type: :thing,
          resolve: fn
            (_, %{context: %{thing: id}}) -> {:ok, @db |> Map.get(id)}
            (_, _) -> {:error, "No :id context provided"}
          end
        ],
        thing: [
          type: :thing,
          args: args(
            id: [
              description: "id of the thing",
              type: non_null(:string)
            ],
            deprecated_arg: deprecate([
              description: "This is a deprecated arg",
              type: :string
            ]),
            deprecated_non_null_arg: deprecate([
              description: "This is a non-null deprecated arg",
              type: non_null(:string)
            ]),
            deprecated_arg_with_reason: deprecate([
              description: "This is a deprecated arg with a reason",
              type: :string
            ], reason: "reason"),
            deprecated_non_null_arg_with_reason: deprecate([
              description: "This is a non-null deprecated arg with a reasor",
              type: non_null(:string)
            ], reason: "reason"),
          ),
          resolve: fn
            (%{id: id}, _) ->
              {:ok, @db |> Map.get(id)}
          end
        ],
        deprecated_thing: deprecate([
          type: :thing,
          args: args(
            id: [
              description: "id of the thing",
              type: non_null(:string)
            ]
          ),
          resolve: fn
            (%{id: id}, _) ->
              {:ok, @db |> Map.get(id)}
          end
        ]),
        deprecated_thing_with_reason: deprecate([
          type: :thing,
          args: args(
            id: [
              description: "id of the thing",
              type: non_null(:string)
            ]
          ),
          resolve: fn
            (%{id: id}, _) ->
              {:ok, @db |> Map.get(id)}
          end
        ], reason: "use `thing' instead")
      )
    }
  end

  @absinthe :type
  def input_thing do
    %Type.InputObjectType{
      description: "A thing as input",
      fields: fields(
        value: [type: :int],
        deprecated_field: deprecate([type: :string]),
        deprecated_field_with_reason: deprecate([type: :string], reason: "reason"),
        deprecated_non_null_field: deprecate([type: non_null(:string)]),
        deprecated_non_null_field_with_reason: deprecate([type: :string], reason: "reason")
      )
    }
  end

  @absinthe :type
  def thing do
    %Type.ObjectType{
      description: "A thing",
      fields: fields(
        id: [
          type: %Type.NonNull{of_type: :string},
          description: "The ID of the thing"
        ],
        name: [
          type: :string,
          description: "The name of the thing"
        ],
        value: [
          type: :int,
          description: "The value of the thing"
        ],
        other_thing: [
          type: :thing,
          resolve: fn (_, %{resolution: %{target: %{id: id}}}) ->
            case id do
              "foo" -> {:ok, @db |> Map.get("bar")}
              "bar" -> {:ok, @db |> Map.get("foo")}
            end
          end
        ]
      )
    }
  end

end
