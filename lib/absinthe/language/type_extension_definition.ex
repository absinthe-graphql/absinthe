defmodule Absinthe.Language.TypeExtensionDefinition do
  @moduledoc false

  alias Absinthe.{Language, Blueprint}

  defstruct definition: nil,
            loc: %{line: nil}

  @type t :: %__MODULE__{
          definition: Language.ObjectTypeDefinition.t(),
          loc: Language.loc_t()
        }

  defimpl Blueprint.Draft do
    def convert(node, doc) do
      %Absinthe.Blueprint.Schema.TypeExtensionDefinition{
        definition: Blueprint.Draft.convert(node.definition, doc),
        source_location: source_location(node)
      }
    end

    defp source_location(%{loc: nil}), do: nil
    defp source_location(%{loc: loc}), do: Blueprint.SourceLocation.at(loc)
  end
end
