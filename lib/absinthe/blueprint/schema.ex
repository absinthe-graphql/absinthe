defmodule Absinthe.Blueprint.Schema do

  @moduledoc false

  alias __MODULE__

  @type type_t ::
      Schema.EnumTypeDefinition.t
    | Schema.InputObjectTypeDefinition.t
    | Schema.InterfaceTypeDefinition.t
    | Schema.ObjectTypeDefinition.t
    | Schema.ScalarTypeDefinition.t
    | Schema.UnionTypeDefinition.t

  @type t :: type_t | Schema.DirectiveDefinition.t
end
