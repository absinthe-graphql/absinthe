defmodule Absinthe.Blueprint.IDL do

  alias Absinthe.Blueprint

  @type type_t :: Blueprint.IDL.EnumTypeDefinition.t
  | Blueprint.IDL.InputObjectTypeDefinition.t
  | Blueprint.IDL.InterfaceTypeDefinition.t
  | Blueprint.IDL.ObjectTypeDefinition.t
  | Blueprint.IDL.ScalarTypeDefinition.t
  | Blueprint.IDL.UnionTypeDefinition.t

end
