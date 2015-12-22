defmodule Absinthe.Utility.TypeInfo do

  @type t :: %{schema: Absinthe.Type.Schema.t, type_stack: [nil | Absinthe.Type.output_t], parent_type_stack: [nil | Absinthe.Type.composite_t], input_type_stack: [nil | Absinthe.Type.input_t], field_def_stack: [nil | Absinthe.Type.FieldDefinition.t], directive: nil | Absinthe.Type.Directive.t, argument: nil | Absinthe.Argument.t}
  defstruct schema: nil, type_stack: [], parent_type_stack: [], input_type_stack: [], field_def_stack: [], directive: nil, argument: nil

end
