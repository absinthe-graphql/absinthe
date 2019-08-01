defmodule Absinthe.Language.InputValueDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:name, :type]
  defstruct [
    :name,
    :type,
    description: nil,
    default_value: nil,
    directives: [],
    loc: %{line: nil}
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          description: nil | String.t(),
          type: Language.input_t(),
          default_value: Language.input_t(),
          directives: [Language.Directive.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.InputValueDefinition{
        name: Macro.underscore(node.name),
        description: node.description,
        type: Blueprint.Draft.convert(node.type, doc),
        identifier: Macro.underscore(node.name) |> String.to_atom(),
        default_value: to_term(node.default_value),
        default_value_blueprint: Blueprint.Draft.convert(node.default_value, doc),
        directives: Blueprint.Draft.convert(node.directives, doc),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.SourceLocation.at(loc)

    defp to_term(nil),
      do: nil

    defp to_term(%Language.EnumValue{value: value}),
      do: value |> Macro.underscore() |> String.to_atom()

    defp to_term(%Language.ListValue{values: values}),
      do: Enum.map(values, &to_term/1)

    defp to_term(%Language.ObjectValue{fields: fields}),
      do: Enum.into(fields, %{}, &{String.to_atom(&1.name), to_term(&1.value)})

    defp to_term(%{value: value}),
      do: value
  end
end
