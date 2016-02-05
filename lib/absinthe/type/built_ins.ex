defmodule Absinthe.Type.BuiltIns do
  use Absinthe.Schema.TypeModule
  alias __MODULE__

  import_types BuiltIns.Scalars
  import_types BuiltIns.Directives

end
