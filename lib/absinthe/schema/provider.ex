defmodule Absinthe.Schema.Provider do
  @moduledoc """
  Experimental: Behaviour for providing schema data

  This behaviour is experimental and may change significatly in patch releases.
  """

  @type schema_identifier :: term
  @type type_group :: :all | :referenced

  @callback pipeline(Absinthe.Pipeline.t()) :: Absinthe.Pipeline.t()

  @callback __absinthe_type__(schema_identifier, Absinthe.Type.identifier_t()) ::
              Absinthe.Type.custom_t()

  @callback __absinthe_directive__(schema_identifier, Absinthe.Type.identifier_t()) ::
              Absinthe.Type.custom_t()

  @callback __absinthe_types__(schema_identifier) :: [{atom, binary}]

  @callback __absinthe_types__(schema_identifier, type_group) :: [
              {Absinthe.Type.identifier_t(), Absinthe.Type.identifier_t()}
            ]

  @callback __absinthe_directives__(schema_identifier) :: Absinthe.Type.Directive.t()

  @callback __absinthe_interface_implementors__(schema_identifier) :: term

  @callback __absinthe_prototype_schema__(schema_identifier) :: schema_identifier
end
