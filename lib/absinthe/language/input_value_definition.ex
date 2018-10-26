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
        name: node.name,
        description: node.description,
        type: Blueprint.Draft.convert(node.type, doc),
        identifier: Macro.underscore(node.name) |> String.to_atom(),
        default_value: Blueprint.Draft.convert(node.default_value, doc),
        directives: Blueprint.Draft.convert(node.directives, doc),
        source_location: source_location(node),
        __reference__: %{
          location: source_location(node) |> Map.put(:file, "TODO")
        }
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.SourceLocation.at(loc)
  end
end
