defmodule Absinthe.Schema.Prototype.Notation do
  @moduledoc false

  defmacro __using__(opts \\ []) do
    content(opts)
  end

  def content(_opts \\ []) do
    quote do
      use Absinthe.Schema
      @schema_provider Absinthe.Schema.Compiled
      @pipeline_modifier __MODULE__

      directive :deprecated do
        description "Marks an element of a GraphQL schema as no longer supported."
        arg :reason, :string

        repeatable false

        on [
          :field_definition,
          :input_field_definition,
          # Technically, argument deprecation is not yet defined by the GraphQL
          # specification. Absinthe does provide some support, but deprecating
          # arguments is not recommended.
          #
          # For more information, see:
          # - https://github.com/graphql/graphql-spec/pull/525
          # - https://github.com/absinthe-graphql/absinthe/issues/207
          :argument_definition,
          :enum_value
        ]

        expand &__MODULE__.expand_deprecate/2
      end

      directive :specified_by do
        description "Exposes a URL that specifies the behavior of this scalar."

        repeatable false

        arg :url, non_null(:string),
          description: "The URL that specifies the behavior of this scalar."

        on [:scalar]
      end

      # https://spec.graphql.org/September2025/#sec--oneOf
      directive :one_of do
        description """
        The @oneOf built-in directive is used within the type system definition language to indicate an Input Object is a OneOf Input Object.

        A OneOf Input Object is a special variant of Input Object where exactly one field must be set and non-null, all others being omitted.
        This is useful for representing situations where an input may be one of many different options.
        """

        repeatable false
        on [:input_object]

        expand(fn _args, node ->
          %{node | __private__: Keyword.put(node.__private__, :one_of, true)}
        end)
      end

      def pipeline(pipeline) do
        pipeline
        |> Absinthe.Pipeline.without(Absinthe.Phase.Schema.Validation.QueryTypeMustBeObject)
        |> Absinthe.Pipeline.without(Absinthe.Phase.Schema.ImportPrototypeDirectives)
        |> Absinthe.Pipeline.without(Absinthe.Phase.Schema.DirectiveImports)
        |> Absinthe.Pipeline.replace(
          Absinthe.Phase.Schema.TypeExtensionImports,
          {Absinthe.Phase.Schema.TypeExtensionImports, []}
        )
      end

      @doc """
      Add a deprecation (with an optional reason) to a node.
      """
      @spec expand_deprecate(
              arguments :: %{optional(:reason) => String.t()},
              node :: Absinthe.Blueprint.node_t()
            ) :: Absinthe.Blueprint.node_t()
      def expand_deprecate(arguments, node) do
        %{node | deprecation: %Absinthe.Type.Deprecation{reason: arguments[:reason]}}
      end

      defoverridable(pipeline: 1)
    end
  end
end
