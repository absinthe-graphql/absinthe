defmodule Things do
  use Absinthe.Schema

  @db %{
    "foo" => %{id: "foo", name: "Foo", value: 4},
    "bar" => %{id: "bar", name: "Bar", value: 5}
  }

  mutation do

    field :update_thing,
      type: :thing,
      args: [
        id: [type: non_null(:string)],
        thing: [type: non_null(:input_thing)]
      ],
      resolve: fn
        %{id: id, thing: %{value: val}}, _ ->
          found = @db |> Map.get(id)
          {:ok, %{found | value: val}}
        %{id: id, thing: fields}, _ ->
          found = @db |> Map.get(id)
        {:ok, found |> Map.merge(fields)}
      end

  end

  query do

    field :version, :string

    field :bad_resolution,
      type: :thing,
      resolve: fn(_, _) ->
        :not_expected
      end

    field :number,
      type: :string,
      args: [
        val: [type: non_null(:integer)]
      ],
      resolve: fn
       %{val: v}, _ -> {:ok, v |> to_string}
       args, _ -> {:error, "got #{inspect args}"}
      end

    field :thing_by_context,
      type: :thing,
      resolve: fn
        _, %{context: %{thing: id}} ->
          {:ok, @db |> Map.get(id)}
        _, _ ->
          {:error, "No :id context provided"}
      end

    field :thing,
      type: :thing,
      args: [
        id: [
          description: "id of the thing",
          type: non_null(:string)
        ],
        deprecated_arg: [
          description: "This is a deprecated arg",
          type: :string,
          deprecate: true

        ],
        deprecated_non_null_arg: [
          description: "This is a non-null deprecated arg",
          type: non_null(:string),
          deprecate: true
        ],
        deprecated_arg_with_reason: [
          description: "This is a deprecated arg with a reason",
          type: :string,
          deprecate: "reason"
        ],
        deprecated_non_null_arg_with_reason: [
          description: "This is a non-null deprecated arg with a reasor",
          type: non_null(:string),
          deprecate: "reason"
        ],
      ],
      resolve: fn
        %{id: id}, _ ->
          {:ok, @db |> Map.get(id)}
      end

    field :deprecated_thing,
      type: :thing,
      args: [
        id: [
          description: "id of the thing",
          type: non_null(:string)
        ]
      ],
      resolve: fn
        %{id: id}, _ ->
          {:ok, @db |> Map.get(id)}
      end,
      deprecate: true

    field :deprecated_thing_with_reason,
      type: :thing,
      args: [
        id: [
          description: "id of the thing",
          type: non_null(:string)
        ]
      ],
      deprecate: "use `thing' instead",
      resolve: fn
        %{id: id}, _ ->
          {:ok, @db |> Map.get(id)}
      end

  end

  input_object :input_thing do
    description "A thing as input"
    field :value, :integer
    field :deprecated_field, :string, deprecate: true
    field :deprecated_field_with_reason, :string, deprecate: "reason"
    field :deprecated_non_null_field, non_null(:string), deprecate: true
    field :deprecated_non_null_field_with_reason, :string, deprecate: "reason"
  end

  object :thing do
    description "A thing"

    field :id, non_null(:string),
      description: "The ID of the thing"

    field :name, :string,
      description: "The name of the thing"

    field :value, :integer,
      description: "The value of the thing"

    field :other_thing,
      type: :thing,
      resolve: fn (_, %{source: %{id: id}}) ->
        case id do
          "foo" -> {:ok, @db |> Map.get("bar")}
          "bar" -> {:ok, @db |> Map.get("foo")}
        end
      end

  end

end
