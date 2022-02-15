defmodule Absinthe.Blueprint.Schema.TypeExtensionDefinition do
  defstruct definition: nil,
            module: nil,
            source_location: nil,
            # # Added by phases
            flags: %{},
            errors: [],
            __private__: [],
            __reference__: nil
end
