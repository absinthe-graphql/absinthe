defmodule Absinthe.Type.BuiltIns do
  use Absinthe.Schema.Notation
  alias __MODULE__

  import_types BuiltIns.Scalars
  import_types BuiltIns.Directives
  import_types BuiltIns.Introspection

end
