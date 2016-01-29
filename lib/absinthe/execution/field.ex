defmodule Absinthe.Execution.Field do

  @moduledoc """
  Information passed to aid resolution functions, describing the current field's
  execution environment.
  """

  @typedoc """

  ## Options
  - `:adapter` - The execution adapter.
  - `:ast_node` - The current AST node.
  - `:context` - The context passed to `Absinthe.run`.
  - `:definition` - The current field definition.
  - `:parent_type` - The parent type for the field.
  - `:root_value` - The root value passed to `Absinthe.run`, if any.
  - `:schema` - The current schema.
  - `:source` - The resolved parent object; source of this field.
  """
  @type t :: %{adapter: atom, ast_node: Language.t, context: map, definition: Type.Field.t, parent_type: Type.t, root_value: any, schema: Schema.t, source: any}

  defstruct adapter: nil, ast_node: nil, context: nil, definition: nil, parent_type: nil, root_value: nil, schema: nil, source: nil

end
