defmodule Absinthe.Execution.Field do

  @moduledoc """
  Information passed to aid resolution functions, describing the current field's
  execution environment.
  """

  @typedoc """

  ## Options
  - `:ast_node` - The current AST node.
  - `:context` - The context passed to `Absinthe.run`.
  - `:definition` - The current field definition
  - `:root` - The root object passed to `Absinthe.run`, if any.
  - `:schema` - The current schema.
  - `:source` - The resolved parent object; source of this field.
  """
  @type t :: %{ast_node: Language.t, context: map, definition: Type.Field.t, root: any, schema: Schema.t, source: any}

  defstruct ast_node: nil, context: nil, definition: nil, root: nil, schema: nil, source: nil

end
