defmodule Absinthe.Blueprint.Schema do

  alias Absinthe.Blueprint

  @type type_t :: Blueprint.Schema.EnumTypeDefinition.t
  | Blueprint.Schema.InputObjectTypeDefinition.t
  | Blueprint.Schema.InterfaceTypeDefinition.t
  | Blueprint.Schema.ObjectTypeDefinition.t
  | Blueprint.Schema.ScalarTypeDefinition.t
  | Blueprint.Schema.UnionTypeDefinition.t

end
