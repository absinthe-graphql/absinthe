defmodule Absinthe.Language.TypeExtensionDefinition do
  @moduledoc false

  alias Absinthe.Language

  defstruct definition: nil,
            loc: %{start_line: nil}

  @type t :: %__MODULE__{
          definition: Language.ObjectTypeDefinition.t(),
          loc: Language.loc_t()
        }
end
