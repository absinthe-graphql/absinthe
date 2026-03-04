defmodule Absinthe.Type.BuiltIns do
  @moduledoc """
  Built-in types, including scalars, directives, and introspection types.

  This module can be imported using `import_types Absinthe.Type.BuiltIns` in your schema.
  """

  use Absinthe.Schema.Notation

  import_types Absinthe.Type.BuiltIns.Scalars
  import_types Absinthe.Type.BuiltIns.Directives
  import_types Absinthe.Type.BuiltIns.Introspection
end
