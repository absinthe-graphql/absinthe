defmodule ExGraphQL.Utility.TypeInfo do

  @type t :: %{schema: ExGraphQL.Type.Schema.t, type_stack: [nil | ExGraphQL.Type.output_t], parent_type_stack: [nil | ExGraphQL.Type.composite_t], input_type_stack: [nil | ExGraphQL.Type.input_t], field_def_stack: [nil | ExGraphQL.Type.FieldDefinition.t], directive: nil | ExGraphQL.Type.Directive.t, argument: nil | ExGraphQL.Argument.t}
  defstruct schema: nil, type_stack: [], parent_type_stack: [], input_type_stack: [], field_def_stack: [], directive: nil, argument: nil

end
