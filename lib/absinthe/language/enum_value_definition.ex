defmodule Absinthe.Language.EnumValueDefinition do
  @moduledoc false

  alias Absinthe.{Blueprint, Language}

  @enforce_keys [:value]
  defstruct [
    :value,
    description: nil,
    directives: [],
    loc: %{line: nil, column: nil}
  ]

  @type t :: %__MODULE__{
          value: String.t(),
          description: nil | String.t(),
          directives: [Language.Directive.t()],
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Blueprint.Schema.EnumValueDefinition{
        value: node.value |> Macro.underscore() |> String.to_atom(),
        name: node.value,
        identifier: node.value |> Macro.underscore() |> String.to_atom(),
        description: node.description,
        directives: Absinthe.Blueprint.Draft.convert(node.directives, doc),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.SourceLocation.at(loc)
  end
end
