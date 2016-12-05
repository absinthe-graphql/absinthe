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

    @doc """
    Lookup a type definition that is part of a schema.
    """
    @spec lookup_type(Blueprint.t, atom) :: nil | Blueprint.Schema.type_t
    def lookup_type(blueprint, identifier) do
      Enum.find(blueprint.types, fn
        %{identifier: ^identifier} ->
          true
        _ ->
          false
      end)
    end

end
