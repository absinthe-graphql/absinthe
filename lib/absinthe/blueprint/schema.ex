defmodule Absinthe.Blueprint.Schema do
  @moduledoc false

  alias __MODULE__

  @type t ::
          Schema.EnumTypeDefinition.t()
          | Schema.InputObjectTypeDefinition.t()
          | Schema.InterfaceTypeDefinition.t()
          | Schema.ObjectTypeDefinition.t()
          | Schema.ScalarTypeDefinition.t()
          | Schema.UnionTypeDefinition.t()
end
