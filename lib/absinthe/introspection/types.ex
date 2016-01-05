defmodule Absinthe.Introspection.Types do

  @moduledoc false

  use Absinthe.Type.Definitions
  alias Absinthe.Flag
  alias Absinthe.Type

  @absinthe :type
  def __type do
    %Type.Object{
      name: "__Type",
      description: "Represents scalars, interfaces, object types, unions, enums in the system",
      fields: fields(
        kind: [
          type: :string,
          resolve: fn
            _, %{resolution: %{target: %Type.Scalar{}}} ->
              {:ok, "SCALAR"}
          end
        ],
        name: [type: :string],
        description: [type: :string],
        fields: [
          type: list_of(:__field),
          args: args(
            include_deprecated: [
              type: :boolean,
              default_value: false
            ]
          ),
          resolve: fn
            %{include_deprecated: show_deprecated}, %{resolution: %{target: target}} ->
              target.fields
              |> Enum.filter(fn
                %{deprecation: is_deprecated} ->
                  !!is_deprecated == !!show_deprecated
              end)
              |> Flag.as(:ok)
          end
        ],
        interfaces: [type: list_of(:__type)],
        possible_types: [types: list_of(:__type)],
        enum_values: [
          type: list_of(:__enumvalue),
          args: args(
            include_deprecated: [
              type: :boolean,
              default_value: false
            ]
          )
        ],
        input_fields: [type: list_of(:__inputvalue)],
        of_type: [type: :__type]
      )
    }
  end

  @absinthe :type
  def __field do
    %Type.Object{
      fields: fields(
        name: [type: :string]
      )
    }
  end

  # TODO __enumvalue, __inputvalue,

end
