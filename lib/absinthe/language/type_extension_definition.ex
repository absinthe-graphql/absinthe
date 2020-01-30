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
    def convert(node, _doc) do
      raise Absinthe.Schema.Notation.Error,
            """
            \n
            SDL Compilation failed:
            -----------------------
            Keyword `extend` is not yet supported (#{inspect(node.loc)})
            """
    end
  end
end
