defmodule Absinthe.Type.BuiltIns do
  @moduledoc """
  Aggregates build in data types

  It imports types from:
  - `Absinthe.Type.BuiltIns.Scalars`
  - `Absinthe.Type.BuiltIns.Directives`
  - `Absinthe.Type.BuiltIns.Introspection`
  """

  use Absinthe.Schema.Notation
  alias __MODULE__

  import_types BuiltIns.Scalars
  import_types BuiltIns.Directives
  import_types BuiltIns.Introspection

end
