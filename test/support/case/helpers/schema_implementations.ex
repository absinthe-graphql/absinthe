defmodule Absinthe.Case.Helpers.SchemaImplementations do
  def schema_implementations(module) do
    [
      Module.safe_concat(module, MacroSchema),
      Module.safe_concat(module, SDLSchema)
    ]
  end
end
