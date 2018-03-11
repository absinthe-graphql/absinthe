defmodule Absinthe.Type.BuiltIns do
  built_in_types =
    [
      Absinthe.Type.BuiltIns.Scalars,
      Absinthe.Type.BuiltIns.Directives,
      Absinthe.Type.BuiltIns.Introspection
    ]
    |> Enum.map(&Absinthe.Utils.describe_builtin_module/1)

  @moduledoc """
  Built in data types

  #{built_in_types}
  """

  use Absinthe.Schema.Notation

  import_types Absinthe.Type.BuiltIns.Scalars
  import_types Absinthe.Type.BuiltIns.Directives
  import_types Absinthe.Type.BuiltIns.Introspection
end
