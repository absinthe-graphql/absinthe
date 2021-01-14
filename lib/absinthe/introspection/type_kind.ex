defmodule Absinthe.Introspection.TypeKind do
  @moduledoc false

  # https://spec.graphql.org/draft/#sec-Type-Kinds

  defmacro __using__(kind) do
    quote do
      @behaviour unquote(__MODULE__)
      def kind, do: unquote(kind)
    end
  end

  @type type_kind ::
          :scalar
          | :object
          | :interface
          | :union
          | :enum
          | :input_object
          | :list
          | :non_null

  @callback kind() :: type_kind()

  def values do
    [
      :scalar,
      :object,
      :interface,
      :union,
      :enum,
      :input_object,
      :list,
      :non_null
    ]
  end
end
